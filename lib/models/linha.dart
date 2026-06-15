import 'package:uuid/uuid.dart';

/// Representa uma linha de produção pertencente a uma fábrica.
///
/// O [id] é um UUID v4 gerado na criação. [fabricaId] referencia a fábrica
/// dona da linha (chave estrangeira para `fabricas.id`).
class Linha {
  final String id;
  final String fabricaId;
  final String nome;
  final String? observacoes;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Linha({
    required this.id,
    required this.fabricaId,
    required this.nome,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Cria uma nova linha, gerando um UUID e definindo os timestamps para agora.
  factory Linha.novo({
    required String fabricaId,
    required String nome,
    String? observacoes,
  }) {
    final agora = DateTime.now();
    return Linha(
      id: const Uuid().v4(),
      fabricaId: fabricaId,
      nome: nome,
      observacoes: observacoes,
      criadoEm: agora,
      atualizadoEm: agora,
    );
  }

  /// Reconstrói uma linha a partir de uma linha do banco.
  factory Linha.fromMap(Map<String, Object?> map) {
    return Linha(
      id: map['id'] as String,
      fabricaId: map['fabrica_id'] as String,
      nome: map['nome'] as String,
      observacoes: map['observacoes'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
    );
  }

  /// Converte a linha para o formato de linha do banco (colunas snake_case).
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'fabrica_id': fabricaId,
      'nome': nome,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}
