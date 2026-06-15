import 'package:uuid/uuid.dart';

/// Os três setores fixos que existem dentro de cada linha de produção.
///
/// O valor salvo no banco é o [name] do enum (ex.: `cozinha`); [rotulo] é o
/// texto exibido na interface.
enum TipoSetor {
  cozinha('Cozinha'),
  embalagem('Embalagem'),
  estoque('Estoque');

  const TipoSetor(this.rotulo);

  final String rotulo;

  static TipoSetor porNome(String? nome) {
    return TipoSetor.values.firstWhere(
      (t) => t.name == nome,
      orElse: () => TipoSetor.cozinha,
    );
  }
}

/// Representa um setor (Cozinha, Embalagem ou Estoque) de uma linha.
///
/// Guarda os dados de processo daquele setor. Quais campos fazem sentido
/// depende do [tipo]:
/// - **Cozinha**: capacidade, velocidade, skus, maoDeObra.
/// - **Embalagem**: velocidade, skus, maoDeObra.
/// - **Estoque**: dimensoesCaixas, peso, montagemPallets.
///
/// [outrasInformacoes] vale para todos os tipos. Todos os campos de processo
/// são opcionais.
class Setor {
  final String id;
  final String linhaId;
  final TipoSetor tipo;

  // Cozinha / Embalagem
  final String? capacidade;
  final String? velocidade;
  final String? skus;
  final int? maoDeObra;

  // Estoque
  final String? dimensoesCaixas;
  final String? peso;
  final String? montagemPallets;

  // Todos
  final String? outrasInformacoes;

  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Setor({
    required this.id,
    required this.linhaId,
    required this.tipo,
    this.capacidade,
    this.velocidade,
    this.skus,
    this.maoDeObra,
    this.dimensoesCaixas,
    this.peso,
    this.montagemPallets,
    this.outrasInformacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Cria um setor "em branco" (sem dados de processo) para um [tipo].
  /// Usado ao criar uma linha (que já nasce com os 3 setores).
  factory Setor.vazio({required String linhaId, required TipoSetor tipo}) {
    final agora = DateTime.now();
    return Setor(
      id: const Uuid().v4(),
      linhaId: linhaId,
      tipo: tipo,
      criadoEm: agora,
      atualizadoEm: agora,
    );
  }

  factory Setor.fromMap(Map<String, Object?> map) {
    return Setor(
      id: map['id'] as String,
      linhaId: map['linha_id'] as String,
      tipo: TipoSetor.porNome(map['tipo'] as String?),
      capacidade: map['capacidade'] as String?,
      velocidade: map['velocidade'] as String?,
      skus: map['skus'] as String?,
      maoDeObra: map['mao_de_obra'] as int?,
      dimensoesCaixas: map['dimensoes_caixas'] as String?,
      peso: map['peso'] as String?,
      montagemPallets: map['montagem_pallets'] as String?,
      outrasInformacoes: map['outras_informacoes'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'linha_id': linhaId,
      'tipo': tipo.name,
      'capacidade': capacidade,
      'velocidade': velocidade,
      'skus': skus,
      'mao_de_obra': maoDeObra,
      'dimensoes_caixas': dimensoesCaixas,
      'peso': peso,
      'montagem_pallets': montagemPallets,
      'outras_informacoes': outrasInformacoes,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }

  /// `true` quando nenhum campo de processo foi preenchido.
  bool get semDados =>
      capacidade == null &&
      velocidade == null &&
      skus == null &&
      maoDeObra == null &&
      dimensoesCaixas == null &&
      peso == null &&
      montagemPallets == null &&
      outrasInformacoes == null;
}
