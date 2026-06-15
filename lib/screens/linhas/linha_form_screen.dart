import 'package:flutter/material.dart';

import '../../models/fabrica.dart';
import '../../models/linha.dart';
import '../../repositories/linha_repository.dart';

/// Formulário de criação e edição de uma linha de produção.
///
/// Sempre recebe a [fabrica] dona. Passe [linha] para editar um registro
/// existente; deixe nulo para criar uma nova. Ao salvar com sucesso, retorna
/// `true` via [Navigator.pop].
class LinhaFormScreen extends StatefulWidget {
  const LinhaFormScreen({super.key, required this.fabrica, this.linha});

  final Fabrica fabrica;
  final Linha? linha;

  bool get isEdicao => linha != null;

  @override
  State<LinhaFormScreen> createState() => _LinhaFormScreenState();
}

class _LinhaFormScreenState extends State<LinhaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final LinhaRepository _repository = LinhaRepository();

  late final TextEditingController _nomeController;
  late final TextEditingController _observacoesController;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final l = widget.linha;
    _nomeController = TextEditingController(text: l?.nome ?? '');
    _observacoesController = TextEditingController(text: l?.observacoes ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _observacoesController.dispose();
    super.dispose();
  }

  /// Converte texto vazio em `null` para não gravar strings em branco no banco.
  String? _ouNulo(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final nome = _nomeController.text.trim();
    final observacoes = _ouNulo(_observacoesController.text);

    try {
      if (widget.isEdicao) {
        final original = widget.linha!;
        final atualizada = Linha(
          id: original.id,
          fabricaId: original.fabricaId,
          nome: nome,
          observacoes: observacoes,
          criadoEm: original.criadoEm,
          atualizadoEm: DateTime.now(),
        );
        await _repository.atualizar(atualizada);
      } else {
        final nova = Linha.novo(
          fabricaId: widget.fabrica.id,
          nome: nome,
          observacoes: observacoes,
        );
        await _repository.inserir(nova);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _salvando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao salvar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdicao ? 'Editar linha' : 'Nova linha'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Fábrica: ${widget.fabrica.nome}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex.: Linha 1 / Montagem',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da linha.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoesController,
              decoration: const InputDecoration(
                labelText: 'Observações',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
              minLines: 3,
              maxLines: 6,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _salvando ? null : _salvar,
              icon: _salvando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(_salvando ? 'Salvando...' : 'Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
