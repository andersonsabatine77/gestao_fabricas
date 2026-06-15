import 'package:uuid/uuid.dart';

/// Representa um equipamento de um setor, com seus dados de fabricação.
///
/// O [id] é um UUID v4 gerado na criação. [setorId] referencia o setor dono
/// (chave estrangeira para `setores.id`). Todos os campos além de [nome] são
/// opcionais.
class Equipamento {
  final String id;
  final String setorId;
  final String nome;
  final String? fabricante;
  final String? modelo;
  final String? numeroSerie;
  final int? anoFabricacao;
  final String? observacoes;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Equipamento({
    required this.id,
    required this.setorId,
    required this.nome,
    this.fabricante,
    this.modelo,
    this.numeroSerie,
    this.anoFabricacao,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Cria um novo equipamento, gerando um UUID e os timestamps para agora.
  factory Equipamento.novo({
    required String setorId,
    required String nome,
    String? fabricante,
    String? modelo,
    String? numeroSerie,
    int? anoFabricacao,
    String? observacoes,
  }) {
    final agora = DateTime.now();
    return Equipamento(
      id: const Uuid().v4(),
      setorId: setorId,
      nome: nome,
      fabricante: fabricante,
      modelo: modelo,
      numeroSerie: numeroSerie,
      anoFabricacao: anoFabricacao,
      observacoes: observacoes,
      criadoEm: agora,
      atualizadoEm: agora,
    );
  }

  factory Equipamento.fromMap(Map<String, Object?> map) {
    return Equipamento(
      id: map['id'] as String,
      setorId: map['setor_id'] as String,
      nome: map['nome'] as String,
      fabricante: map['fabricante'] as String?,
      modelo: map['modelo'] as String?,
      numeroSerie: map['numero_serie'] as String?,
      anoFabricacao: map['ano_fabricacao'] as int?,
      observacoes: map['observacoes'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'setor_id': setorId,
      'nome': nome,
      'fabricante': fabricante,
      'modelo': modelo,
      'numero_serie': numeroSerie,
      'ano_fabricacao': anoFabricacao,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}
