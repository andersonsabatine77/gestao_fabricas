import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/linha.dart';
import '../models/setor.dart';

/// Camada de acesso a dados das linhas de produção.
///
/// Ao inserir uma linha, cria automaticamente os 3 setores fixos
/// (Cozinha, Embalagem e Estoque) numa transação.
class LinhaRepository {
  LinhaRepository({AppDatabase? db})
      : _appDatabase = db ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tabela = 'linhas';

  /// Lista as linhas de uma fábrica em ordem alfabética (ignorando maiúsculas).
  Future<List<Linha>> listarPorFabrica(String fabricaId) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'fabrica_id = ?',
      whereArgs: [fabricaId],
      orderBy: 'nome COLLATE NOCASE ASC',
    );
    return linhas.map(Linha.fromMap).toList();
  }

  /// Busca uma linha pelo [id]; retorna `null` se não existir.
  Future<Linha?> buscarPorId(String id) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Linha.fromMap(linhas.first);
  }

  /// Quantidade de linhas agrupada por fábrica (chave = id da fábrica).
  Future<Map<String, int>> contagemPorFabrica() async {
    final db = await _appDatabase.database;
    final linhas = await db.rawQuery(
      'SELECT fabrica_id, COUNT(*) AS total FROM $_tabela GROUP BY fabrica_id',
    );
    return {
      for (final row in linhas)
        row['fabrica_id'] as String: row['total'] as int,
    };
  }

  /// Insere uma nova linha já criando seus 3 setores fixos.
  Future<void> inserir(Linha linha) async {
    final db = await _appDatabase.database;
    await db.transaction((txn) async {
      await txn.insert(
        _tabela,
        linha.toMap(),
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
      for (final tipo in TipoSetor.values) {
        final setor = Setor.vazio(linhaId: linha.id, tipo: tipo);
        await txn.insert(
          'setores',
          setor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  /// Atualiza uma linha existente (identificada pelo seu `id`).
  Future<void> atualizar(Linha linha) async {
    final db = await _appDatabase.database;
    await db.update(
      _tabela,
      linha.toMap(),
      where: 'id = ?',
      whereArgs: [linha.id],
    );
  }

  /// Apaga a linha de [id] informado (e, em cascata, seus setores).
  Future<void> apagar(String id) async {
    final db = await _appDatabase.database;
    await db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
