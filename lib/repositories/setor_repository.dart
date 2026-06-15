import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/setor.dart';

/// Camada de acesso a dados dos setores (Cozinha, Embalagem e Estoque).
///
/// Setores não são criados nem apagados pelo usuário — eles existem fixos,
/// 3 por linha. Aqui ficam: garantir a existência dos 3, listá-los e salvar
/// os dados de processo.
class SetorRepository {
  SetorRepository({AppDatabase? db})
      : _appDatabase = db ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tabela = 'setores';

  /// Garante que a linha tenha os 3 setores fixos, criando os que faltarem.
  ///
  /// Rede de segurança: linhas novas já nascem com eles via [LinhaRepository],
  /// mas isto cobre dados importados ou incompletos.
  Future<void> garantirSetores(String linhaId) async {
    final db = await _appDatabase.database;
    final existentes = await db.query(
      _tabela,
      columns: ['tipo'],
      where: 'linha_id = ?',
      whereArgs: [linhaId],
    );
    final tipos = existentes
        .map((row) => TipoSetor.porNome(row['tipo'] as String?))
        .toSet();
    for (final tipo in TipoSetor.values) {
      if (!tipos.contains(tipo)) {
        final setor = Setor.vazio(linhaId: linhaId, tipo: tipo);
        await db.insert(
          _tabela,
          setor.toMap(),
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Lista os 3 setores de uma linha, na ordem Cozinha → Embalagem → Estoque.
  Future<List<Setor>> listarPorLinha(String linhaId) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'linha_id = ?',
      whereArgs: [linhaId],
    );
    final setores = linhas.map(Setor.fromMap).toList()
      ..sort((a, b) => a.tipo.index.compareTo(b.tipo.index));
    return setores;
  }

  /// Busca um setor pelo [id]; retorna `null` se não existir.
  Future<Setor?> buscarPorId(String id) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Setor.fromMap(linhas.first);
  }

  /// Salva os dados de processo de um setor existente.
  Future<void> atualizar(Setor setor) async {
    final db = await _appDatabase.database;
    await db.update(
      _tabela,
      setor.toMap(),
      where: 'id = ?',
      whereArgs: [setor.id],
    );
  }
}
