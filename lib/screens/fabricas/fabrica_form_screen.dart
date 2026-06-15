import 'package:flutter/material.dart';

import '../../models/fabrica.dart';
import '../../repositories/fabrica_repository.dart';

/// Formulário de criação e edição de uma fábrica.
///
/// Passe [fabrica] para editar um registro existente; deixe nulo para criar
/// uma nova. Ao salvar com sucesso, retorna `true` via [Navigator.pop].
class FabricaFormScreen extends StatefulWidget {
  const FabricaFormScreen({super.key, this.fabrica});

  final Fabrica? fabrica;

  bool get isEdicao => fabrica != null;

  @override
  State<FabricaFormScreen> createState() => _FabricaFormScreenState();
}

class _FabricaFormScreenState extends State<FabricaFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final FabricaRepository _repository = FabricaRepository();

  late final TextEditingController _nomeController;
  late final TextEditingController _localizacaoController;
  late final TextEditingController _observacoesController;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final f = widget.fabrica;
    _nomeController = TextEditingController(text: f?.nome ?? '');
    _localizacaoController = TextEditingController(text: f?.localizacao ?? '');
    _observacoesController = TextEditingController(text: f?.observacoes ?? '');
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _localizacaoController.dispose();
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
    final localizacao = _ouNulo(_localizacaoController.text);
    final observacoes = _ouNulo(_observacoesController.text);

    try {
      if (widget.isEdicao) {
        final original = widget.fabrica!;
        final atualizada = Fabrica(
          id: original.id,
          nome: nome,
          localizacao: localizacao,
          observacoes: observacoes,
          criadoEm: original.criadoEm,
          atualizadoEm: DateTime.now(),
        );
        await _repository.atualizar(atualizada);
      } else {
        final nova = Fabrica.novo(
          nome: nome,
          localizacao: localizacao,
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
        title: Text(widget.isEdicao ? 'Editar fábrica' : 'Nova fábrica'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nomeController,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex.: Unidade Centro',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome da fábrica.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _localizacaoController,
              decoration: const InputDecoration(
                labelText: 'Localização',
                hintText: 'Cidade, endereço ou referência',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.sentences,
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
