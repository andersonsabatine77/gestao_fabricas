import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';

/// Abrangência da exportação.
enum EscopoExport { tudo, fabrica, linha }

/// Como aplicar os dados importados.
enum ModoImport {
  /// Apaga tudo o que existe e grava apenas o conteúdo do arquivo.
  sobrescrever,

  /// Mantém o que existe e adiciona/atualiza com o conteúdo do arquivo.
  mesclar,
}

/// Resultado de uma importação (quantidades processadas).
class ResultadoImport {
  const ResultadoImport({
    required this.fabricas,
    required this.linhas,
    required this.equipamentos,
  });

  final int fabricas;
  final int linhas;
  final int equipamentos;
}

/// Serviço de importação/exportação dos dados em JSON.
///
/// O formato exportado é uma árvore: `fabricas → linhas → setores →
/// equipamentos`, sempre com a chave de topo `fabricas` (mesmo ao exportar
/// uma única fábrica ou linha, a fábrica-pai é incluída).
///
/// Esta classe só lida com dados (banco e JSON); ler/gravar o arquivo em si
/// fica a cargo da camada de UI (file_picker / share_plus).
class BackupService {
  BackupService({AppDatabase? db}) : _appDatabase = db ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const int _schema = 6;

  // ---------------------------------------------------------------------------
  // Exportação
  // ---------------------------------------------------------------------------

  /// Monta a árvore de dados para o [escopo] escolhido e devolve o JSON
  /// formatado, pronto para gravar em arquivo.
  Future<String> exportarJson({
    required EscopoExport escopo,
    String? fabricaId,
    String? linhaId,
  }) async {
    final mapa = await _montar(
      escopo: escopo,
      fabricaId: fabricaId,
      linhaId: linhaId,
    );
    return const JsonEncoder.withIndent('  ').convert(mapa);
  }

  Future<Map<String, Object?>> _montar({
    required EscopoExport escopo,
    String? fabricaId,
    String? linhaId,
  }) async {
    final db = await _appDatabase.database;

    List<Map<String, Object?>> fabricas;
    List<Map<String, Object?>> linhas;
    List<Map<String, Object?>> setores;
    List<Map<String, Object?>> equipamentos;

    switch (escopo) {
      case EscopoExport.tudo:
        fabricas = await db.query('fabricas');
        linhas = await db.query('linhas');
        setores = await db.query('setores');
        equipamentos = await db.query('equipamentos');

      case EscopoExport.fabrica:
        fabricas =
            await db.query('fabricas', where: 'id = ?', whereArgs: [fabricaId]);
        linhas = await db
            .query('linhas', where: 'fabrica_id = ?', whereArgs: [fabricaId]);
        final linhaIds = linhas.map((l) => l['id'] as String).toList();
        setores = await _emIds(db, 'setores', 'linha_id', linhaIds);
        final setorIds = setores.map((s) => s['id'] as String).toList();
        equipamentos = await _emIds(db, 'equipamentos', 'setor_id', setorIds);

      case EscopoExport.linha:
        linhas =
            await db.query('linhas', where: 'id = ?', whereArgs: [linhaId]);
        final fabId =
            linhas.isEmpty ? null : linhas.first['fabrica_id'] as String;
        fabricas = fabId == null
            ? const []
            : await db.query('fabricas', where: 'id = ?', whereArgs: [fabId]);
        setores =
            await db.query('setores', where: 'linha_id = ?', whereArgs: [linhaId]);
        final setorIds = setores.map((s) => s['id'] as String).toList();
        equipamentos = await _emIds(db, 'equipamentos', 'setor_id', setorIds);
    }

    return _aninhar(fabricas, linhas, setores, equipamentos, escopo);
  }

  Future<List<Map<String, Object?>>> _emIds(
    Database db,
    String tabela,
    String coluna,
    List<String> ids,
  ) async {
    if (ids.isEmpty) return const [];
    final marcadores = List.filled(ids.length, '?').join(',');
    return db.rawQuery('SELECT * FROM $tabela WHERE $coluna IN ($marcadores)', ids);
  }

  Map<String, Object?> _aninhar(
    List<Map<String, Object?>> fabricas,
    List<Map<String, Object?>> linhas,
    List<Map<String, Object?>> setores,
    List<Map<String, Object?>> equipamentos,
    EscopoExport escopo,
  ) {
    final equipPorSetor = <String, List<Map<String, Object?>>>{};
    for (final e in equipamentos) {
      (equipPorSetor[e['setor_id'] as String] ??= []).add(Map.of(e));
    }
    final setoresPorLinha = <String, List<Map<String, Object?>>>{};
    for (final s in setores) {
      final m = Map<String, Object?>.of(s);
      m['equipamentos'] = equipPorSetor[s['id']] ?? const [];
      (setoresPorLinha[s['linha_id'] as String] ??= []).add(m);
    }
    final linhasPorFabrica = <String, List<Map<String, Object?>>>{};
    for (final l in linhas) {
      final m = Map<String, Object?>.of(l);
      m['setores'] = setoresPorLinha[l['id']] ?? const [];
      (linhasPorFabrica[l['fabrica_id'] as String] ??= []).add(m);
    }
    final fabricasJson = [
      for (final f in fabricas)
        {
          ...Map<String, Object?>.of(f),
          'linhas': linhasPorFabrica[f['id']] ?? const [],
        },
    ];

    return {
      'app': 'gestao_fabricas',
      'schema': _schema,
      'exportadoEm': DateTime.now().toIso8601String(),
      'escopo': escopo.name,
      'fabricas': fabricasJson,
    };
  }

  // ---------------------------------------------------------------------------
  // Importação
  // ---------------------------------------------------------------------------

  /// Lê o [conteudo] JSON e aplica no banco conforme [modo].
  /// Lança [FormatException] se o arquivo não for reconhecido.
  Future<ResultadoImport> importarJson(
    String conteudo, {
    required ModoImport modo,
  }) async {
    final Object? decodificado;
    try {
      decodificado = jsonDecode(conteudo);
    } catch (_) {
      throw const FormatException('Arquivo inválido: não é um JSON válido.');
    }
    if (decodificado is! Map || decodificado['fabricas'] is! List) {
      throw const FormatException(
        'Arquivo inválido: estrutura de dados não reconhecida.',
      );
    }

    final fabricas = (decodificado['fabricas'] as List)
        .map((e) => (e as Map).cast<String, Object?>())
        .toList();

    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      if (modo == ModoImport.sobrescrever) {
        await txn.delete('fabricas'); // cascata apaga linhas/setores/equip.
        for (final f in fabricas) {
          await _inserirArvore(txn, f);
        }
      } else {
        for (final f in fabricas) {
          await _mesclarFabrica(txn, f);
        }
      }
    });

    return _contar(fabricas);
  }

  // ----- Sobrescrever: inserções diretas -----

  Future<void> _inserirArvore(Transaction txn, Map<String, Object?> f) async {
    final linhas = _filhos(f, 'linhas');
    await txn.insert('fabricas', _semChave(f, 'linhas'),
        conflictAlgorithm: ConflictAlgorithm.replace);
    for (final l in linhas) {
      final setores = _filhos(l, 'setores');
      await txn.insert('linhas', _semChave(l, 'setores'),
          conflictAlgorithm: ConflictAlgorithm.replace);
      for (final s in setores) {
        final equipamentos = _filhos(s, 'equipamentos');
        await txn.insert('setores', _semChave(s, 'equipamentos'),
            conflictAlgorithm: ConflictAlgorithm.replace);
        for (final e in equipamentos) {
          await txn.insert('equipamentos', Map<String, Object?>.of(e),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      }
    }
  }

  // ----- Mesclar: upsert preservando o que já existe -----

  Future<void> _mesclarFabrica(Transaction txn, Map<String, Object?> f) async {
    final linhas = _filhos(f, 'linhas');
    await _upsertPorId(txn, 'fabricas', _semChave(f, 'linhas'));
    for (final l in linhas) {
      await _mesclarLinha(txn, l);
    }
  }

  Future<void> _mesclarLinha(Transaction txn, Map<String, Object?> l) async {
    final setores = _filhos(l, 'setores');
    await _upsertPorId(txn, 'linhas', _semChave(l, 'setores'));
    for (final s in setores) {
      final equipamentos = _filhos(s, 'equipamentos');
      final setorIdDestino = await _mesclarSetor(txn, _semChave(s, 'equipamentos'));
      for (final e in equipamentos) {
        final equip = Map<String, Object?>.of(e)..['setor_id'] = setorIdDestino;
        await _upsertPorId(txn, 'equipamentos', equip);
      }
    }
  }

  /// Setores são identificados por (linha_id, tipo) — não pelo id — para
  /// respeitar o UNIQUE e preservar os equipamentos já vinculados.
  /// Retorna o id do setor de destino (existente ou recém-inserido).
  Future<String> _mesclarSetor(Transaction txn, Map<String, Object?> s) async {
    final linhaId = s['linha_id'] as String;
    final tipo = s['tipo'] as String;
    final existentes = await txn.query(
      'setores',
      columns: ['id'],
      where: 'linha_id = ? AND tipo = ?',
      whereArgs: [linhaId, tipo],
      limit: 1,
    );
    if (existentes.isNotEmpty) {
      final id = existentes.first['id'] as String;
      final dados = Map<String, Object?>.of(s)..['id'] = id;
      await txn.update('setores', dados, where: 'id = ?', whereArgs: [id]);
      return id;
    }
    await txn.insert('setores', Map<String, Object?>.of(s),
        conflictAlgorithm: ConflictAlgorithm.replace);
    return s['id'] as String;
  }

  Future<void> _upsertPorId(
    Transaction txn,
    String tabela,
    Map<String, Object?> linha,
  ) async {
    final id = linha['id'];
    final existentes = await txn.query(tabela,
        columns: ['id'], where: 'id = ?', whereArgs: [id], limit: 1);
    if (existentes.isNotEmpty) {
      await txn.update(tabela, linha, where: 'id = ?', whereArgs: [id]);
    } else {
      await txn.insert(tabela, linha);
    }
  }

  // ----- Auxiliares -----

  List<Map<String, Object?>> _filhos(Map<String, Object?> m, String chave) {
    final lista = m[chave];
    if (lista is! List) return const [];
    return lista.map((e) => (e as Map).cast<String, Object?>()).toList();
  }

  Map<String, Object?> _semChave(Map<String, Object?> m, String chave) {
    final copia = Map<String, Object?>.of(m);
    copia.remove(chave);
    return copia;
  }

  ResultadoImport _contar(List<Map<String, Object?>> fabricas) {
    var linhas = 0;
    var equipamentos = 0;
    for (final f in fabricas) {
      final ls = _filhos(f, 'linhas');
      linhas += ls.length;
      for (final l in ls) {
        for (final s in _filhos(l, 'setores')) {
          equipamentos += _filhos(s, 'equipamentos').length;
        }
      }
    }
    return ResultadoImport(
      fabricas: fabricas.length,
      linhas: linhas,
      equipamentos: equipamentos,
    );
  }
}
