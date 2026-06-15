import 'package:sqflite/sqflite.dart';

import '../core/database/app_database.dart';
import '../models/equipamento.dart';

/// Camada de acesso a dados dos equipamentos.
class EquipamentoRepository {
  EquipamentoRepository({AppDatabase? db})
      : _appDatabase = db ?? AppDatabase.instance;

  final AppDatabase _appDatabase;

  static const String _tabela = 'equipamentos';

  /// Lista os equipamentos de um setor em ordem alfabética (ignora maiúsculas).
  Future<List<Equipamento>> listarPorSetor(String setorId) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'setor_id = ?',
      whereArgs: [setorId],
      orderBy: 'nome COLLATE NOCASE ASC',
    );
    return linhas.map(Equipamento.fromMap).toList();
  }

  /// Busca um equipamento pelo [id]; retorna `null` se não existir.
  Future<Equipamento?> buscarPorId(String id) async {
    final db = await _appDatabase.database;
    final linhas = await db.query(
      _tabela,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (linhas.isEmpty) return null;
    return Equipamento.fromMap(linhas.first);
  }

  /// Insere um novo equipamento.
  Future<void> inserir(Equipamento equipamento) async {
    final db = await _appDatabase.database;
    await db.insert(
      _tabela,
      equipamento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  /// Atualiza um equipamento existente (identificado pelo seu `id`).
  Future<void> atualizar(Equipamento equipamento) async {
    final db = await _appDatabase.database;
    await db.update(
      _tabela,
      equipamento.toMap(),
      where: 'id = ?',
      whereArgs: [equipamento.id],
    );
  }

  /// Apaga o equipamento de [id] informado.
  Future<void> apagar(String id) async {
    final db = await _appDatabase.database;
    await db.delete(_tabela, where: 'id = ?', whereArgs: [id]);
  }
}
