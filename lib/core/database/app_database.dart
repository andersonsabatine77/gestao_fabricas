import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Gerencia a conexão única (singleton) com o banco SQLite local do app.
///
/// Todo o acesso ao banco passa por [AppDatabase.instance]. A conexão é
/// aberta de forma preguiçosa (lazy) na primeira vez em que [database] é lido.
///
/// Estrutura atual (v6):
///   fabricas → linhas → setores (3 fixos por linha: cozinha/embalagem/estoque)
///   → equipamentos.
///
/// Como expandir no futuro (novos campos ou tabelas):
///   1. Incremente [_versao].
///   2. Crie/altere em [_onCreate] (vale para instalações novas).
///   3. Adicione a migração correspondente em [_onUpgrade].
class AppDatabase {
  AppDatabase._();

  /// Instância única compartilhada por todo o app.
  static final AppDatabase instance = AppDatabase._();

  static const String _nomeArquivo = 'gestao_fabricas.db';

  /// Versão do schema. Histórico:
  ///   v1–v5 — modelo antigo (setores livres + processos).
  ///   v6    — reestruturação: 3 setores fixos por linha + equipamentos com
  ///           dados de fabricação; tabela `processos` removida.
  static const int _versao = 6;

  Database? _database;

  /// Retorna a conexão aberta com o banco, abrindo-a se necessário.
  Future<Database> get database async {
    return _database ??= await _abrir();
  }

  Future<Database> _abrir() async {
    final caminho = join(await getDatabasesPath(), _nomeArquivo);
    return openDatabase(
      caminho,
      version: _versao,
      onConfigure: _onConfigure,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onConfigure(Database db) async {
    // Habilita chaves estrangeiras (necessário para o ON DELETE CASCADE).
    await db.execute('PRAGMA foreign_keys = ON');
  }

  Future<void> _onCreate(Database db, int version) async {
    await _criarTabelaFabricas(db);
    await _criarTabelaLinhas(db);
    await _criarTabelaSetores(db);
    await _criarTabelaEquipamentos(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // A estrutura mudou de forma incompatível na v6 (abas fixas e remoção de
    // processos). Conforme combinado, o banco é recriado do zero.
    if (oldVersion < 6) {
      await _recriarSchema(db);
    }
  }

  /// Apaga todas as tabelas conhecidas e recria o schema atual.
  Future<void> _recriarSchema(Database db) async {
    const tabelas = ['processos', 'equipamentos', 'setores', 'linhas', 'fabricas'];
    for (final tabela in tabelas) {
      await db.execute('DROP TABLE IF EXISTS $tabela');
    }
    await _onCreate(db, _versao);
  }

  Future<void> _criarTabelaFabricas(Database db) async {
    await db.execute('''
      CREATE TABLE fabricas (
        id TEXT PRIMARY KEY,
        nome TEXT NOT NULL,
        localizacao TEXT,
        observacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL
      )
    ''');
  }

  Future<void> _criarTabelaLinhas(Database db) async {
    await db.execute('''
      CREATE TABLE linhas (
        id TEXT PRIMARY KEY,
        fabrica_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        observacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (fabrica_id) REFERENCES fabricas (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_linhas_fabrica_id ON linhas (fabrica_id)');
  }

  Future<void> _criarTabelaSetores(Database db) async {
    // Cada linha tem exatamente 3 setores (cozinha, embalagem, estoque),
    // garantidos pelo UNIQUE(linha_id, tipo). Os campos de processo são todos
    // opcionais; quais se aplicam depende do `tipo`.
    await db.execute('''
      CREATE TABLE setores (
        id TEXT PRIMARY KEY,
        linha_id TEXT NOT NULL,
        tipo TEXT NOT NULL,
        capacidade TEXT,
        velocidade TEXT,
        skus TEXT,
        mao_de_obra INTEGER,
        dimensoes_caixas TEXT,
        peso TEXT,
        montagem_pallets TEXT,
        outras_informacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (linha_id) REFERENCES linhas (id) ON DELETE CASCADE,
        UNIQUE (linha_id, tipo)
      )
    ''');
  }

  Future<void> _criarTabelaEquipamentos(Database db) async {
    await db.execute('''
      CREATE TABLE equipamentos (
        id TEXT PRIMARY KEY,
        setor_id TEXT NOT NULL,
        nome TEXT NOT NULL,
        fabricante TEXT,
        modelo TEXT,
        numero_serie TEXT,
        ano_fabricacao INTEGER,
        observacoes TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        FOREIGN KEY (setor_id) REFERENCES setores (id) ON DELETE CASCADE
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_equipamentos_setor_id ON equipamentos (setor_id)',
    );
  }

  /// Fecha a conexão. Útil em testes ou ao encerrar o app.
  Future<void> fechar() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
