import 'package:uuid/uuid.dart';

/// Representa uma fábrica cadastrada.
///
/// O [id] é um UUID v4 gerado uma única vez na criação e nunca muda.
/// Os campos [localizacao] e [observacoes] são opcionais.
class Fabrica {
  final String id;
  final String nome;
  final String? localizacao;
  final String? observacoes;
  final DateTime criadoEm;
  final DateTime atualizadoEm;

  const Fabrica({
    required this.id,
    required this.nome,
    this.localizacao,
    this.observacoes,
    required this.criadoEm,
    required this.atualizadoEm,
  });

  /// Cria uma nova fábrica, gerando um UUID e definindo os timestamps para agora.
  factory Fabrica.novo({
    required String nome,
    String? localizacao,
    String? observacoes,
  }) {
    final agora = DateTime.now();
    return Fabrica(
      id: const Uuid().v4(),
      nome: nome,
      localizacao: localizacao,
      observacoes: observacoes,
      criadoEm: agora,
      atualizadoEm: agora,
    );
  }

  /// Reconstrói uma fábrica a partir de uma linha do banco.
  factory Fabrica.fromMap(Map<String, Object?> map) {
    return Fabrica(
      id: map['id'] as String,
      nome: map['nome'] as String,
      localizacao: map['localizacao'] as String?,
      observacoes: map['observacoes'] as String?,
      criadoEm: DateTime.parse(map['criado_em'] as String),
      atualizadoEm: DateTime.parse(map['atualizado_em'] as String),
    );
  }

  /// Converte a fábrica para o formato de linha do banco (colunas snake_case).
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'nome': nome,
      'localizacao': localizacao,
      'observacoes': observacoes,
      'criado_em': criadoEm.toIso8601String(),
      'atualizado_em': atualizadoEm.toIso8601String(),
    };
  }
}
