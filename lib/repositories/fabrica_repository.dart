import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/fabrica.dart';

/// Camada de acesso a dados das fábricas.
///
/// Concentra todas as operações de leitura e escrita na tabela `fabricas`,
/// isolando o restante do app dos detalhes do SQLite.
class FabricaRepository {
  FabricaRepository({AppDatabase? db})
      : _appDatabase = db ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tabela = 'fabricas';

  /// Lista todas as fábricas em ordem alfabética (ignorando maiúsculas).
  Future<List<Fabrica>> listar() async {
    final db = await _appDatabase.database;
    final linhas = await db.query(_tabela, orderBy: 'nome COLLATE NOCASE ASC');
    return linhas.map(Fabrica.fromMap).toList();
  }

  /// Busca uma fábrica pelo [id]; retorna `null` se não existir.
  Future<Fabrica?> buscarPorId(String id) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Fabrica.fromMap(linhas.first);
  }

  /// Insere uma nova fábrica.
  Future<void> inserir(Fabrica fabrica) async {
    final db = await _appDatabase.database;
    await db.insert(
      _tabela,
      fabrica.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Atualiza uma fábrica existente (identificada pelo seu `id`).
  Future<void> atualizar(Fabrica fabrica) async {
    final db = await _appDatabase.database;
    await db.update(
      _tabela,
      fabrica.toMap(),
      where: 'id = ?',
      whereArgs: [fabrica.id],
    );
  }

  /// Apaga a fábrica de [id] informado.
  Future<void> apagar(String id) async {
    final db = await _appDatabase.database;
    await db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
