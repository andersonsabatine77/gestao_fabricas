import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/equipamento.dart';
import '../../models/setor.dart';
import '../../repositories/equipamento_repository.dart';

/// Formulário de criação e edição de um equipamento (dados de fabricação).
///
/// Sempre recebe o [setor] dono. Passe [equipamento] para editar; deixe nulo
/// para criar. Ao salvar com sucesso, retorna `true` via [Navigator.pop].
class EquipamentoFormScreen extends StatefulWidget {
  const EquipamentoFormScreen({
    super.key,
    required this.setor,
    this.equipamento,
  });

  final Setor setor;
  final Equipamento? equipamento;

  bool get isEdicao => equipamento != null;

  @override
  State<EquipamentoFormScreen> createState() => _EquipamentoFormScreenState();
}

class _EquipamentoFormScreenState extends State<EquipamentoFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final EquipamentoRepository _repository = EquipamentoRepository();

  late final TextEditingController _nome;
  late final TextEditingController _fabricante;
  late final TextEditingController _modelo;
  late final TextEditingController _numeroSerie;
  late final TextEditingController _anoFabricacao;
  late final TextEditingController _observacoes;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final e = widget.equipamento;
    _nome = TextEditingController(text: e?.nome ?? '');
    _fabricante = TextEditingController(text: e?.fabricante ?? '');
    _modelo = TextEditingController(text: e?.modelo ?? '');
    _numeroSerie = TextEditingController(text: e?.numeroSerie ?? '');
    _anoFabricacao =
        TextEditingController(text: e?.anoFabricacao?.toString() ?? '');
    _observacoes = TextEditingController(text: e?.observacoes ?? '');
  }

  @override
  void dispose() {
    _nome.dispose();
    _fabricante.dispose();
    _modelo.dispose();
    _numeroSerie.dispose();
    _anoFabricacao.dispose();
    _observacoes.dispose();
    super.dispose();
  }

  String? _ouNulo(String texto) {
    final t = texto.trim();
    return t.isEmpty ? null : t;
  }

  int? _paraInt(String texto) {
    final t = texto.trim();
    if (t.isEmpty) return null;
    return int.tryParse(t);
  }

  Future<void> _salvar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final nome = _nome.text.trim();
    final fabricante = _ouNulo(_fabricante.text);
    final modelo = _ouNulo(_modelo.text);
    final numeroSerie = _ouNulo(_numeroSerie.text);
    final anoFabricacao = _paraInt(_anoFabricacao.text);
    final observacoes = _ouNulo(_observacoes.text);

    try {
      if (widget.isEdicao) {
        final original = widget.equipamento!;
        final atualizado = Equipamento(
          id: original.id,
          setorId: original.setorId,
          nome: nome,
          fabricante: fabricante,
          modelo: modelo,
          numeroSerie: numeroSerie,
          anoFabricacao: anoFabricacao,
          observacoes: observacoes,
          criadoEm: original.criadoEm,
          atualizadoEm: DateTime.now(),
        );
        await _repository.atualizar(atualizado);
      } else {
        final novo = Equipamento.novo(
          setorId: widget.setor.id,
          nome: nome,
          fabricante: fabricante,
          modelo: modelo,
          numeroSerie: numeroSerie,
          anoFabricacao: anoFabricacao,
          observacoes: observacoes,
        );
        await _repository.inserir(novo);
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
        title: Text(widget.isEdicao ? 'Editar equipamento' : 'Novo equipamento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Setor: ${widget.setor.tipo.rotulo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nome,
              decoration: const InputDecoration(
                labelText: 'Nome *',
                hintText: 'Ex.: Misturador 01',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Informe o nome do equipamento.';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fabricante,
              decoration: const InputDecoration(
                labelText: 'Fabricante',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _modelo,
              decoration: const InputDecoration(
                labelText: 'Modelo',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _numeroSerie,
              decoration: const InputDecoration(
                labelText: 'Número de série',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _anoFabricacao,
              decoration: const InputDecoration(
                labelText: 'Ano de fabricação',
                hintText: 'Ex.: 2021',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              validator: (value) {
                if (value == null || value.trim().isEmpty) return null;
                final ano = int.tryParse(value.trim());
                if (ano == null || ano < 1900 || ano > 2100) {
                  return 'Informe um ano válido (1900–2100).';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _observacoes,
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
