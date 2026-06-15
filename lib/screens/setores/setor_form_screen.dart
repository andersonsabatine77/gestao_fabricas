import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/setor.dart';
import '../../repositories/setor_repository.dart';

/// Formulário dos dados de processo de um setor.
///
/// Os campos exibidos dependem do [Setor.tipo]:
/// - Cozinha: capacidade, velocidade, SKUs, mão de obra.
/// - Embalagem: velocidade, SKUs, mão de obra.
/// - Estoque: dimensões das caixas, peso, montagem dos pallets.
/// Todos os tipos têm "Outras informações".
class SetorFormScreen extends StatefulWidget {
  const SetorFormScreen({super.key, required this.setor});

  final Setor setor;

  @override
  State<SetorFormScreen> createState() => _SetorFormScreenState();
}

class _SetorFormScreenState extends State<SetorFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final SetorRepository _repository = SetorRepository();

  late final TextEditingController _capacidade;
  late final TextEditingController _velocidade;
  late final TextEditingController _skus;
  late final TextEditingController _maoDeObra;
  late final TextEditingController _dimensoesCaixas;
  late final TextEditingController _peso;
  late final TextEditingController _montagemPallets;
  late final TextEditingController _outras;

  bool _salvando = false;

  @override
  void initState() {
    super.initState();
    final s = widget.setor;
    _capacidade = TextEditingController(text: s.capacidade ?? '');
    _velocidade = TextEditingController(text: s.velocidade ?? '');
    _skus = TextEditingController(text: s.skus ?? '');
    _maoDeObra = TextEditingController(text: s.maoDeObra?.toString() ?? '');
    _dimensoesCaixas = TextEditingController(text: s.dimensoesCaixas ?? '');
    _peso = TextEditingController(text: s.peso ?? '');
    _montagemPallets = TextEditingController(text: s.montagemPallets ?? '');
    _outras = TextEditingController(text: s.outrasInformacoes ?? '');
  }

  @override
  void dispose() {
    _capacidade.dispose();
    _velocidade.dispose();
    _skus.dispose();
    _maoDeObra.dispose();
    _dimensoesCaixas.dispose();
    _peso.dispose();
    _montagemPallets.dispose();
    _outras.dispose();
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

    final tipo = widget.setor.tipo;
    final usaProducao =
        tipo == TipoSetor.cozinha || tipo == TipoSetor.embalagem;

    final atualizado = Setor(
      id: widget.setor.id,
      linhaId: widget.setor.linhaId,
      tipo: tipo,
      capacidade: tipo == TipoSetor.cozinha ? _ouNulo(_capacidade.text) : null,
      velocidade: usaProducao ? _ouNulo(_velocidade.text) : null,
      skus: usaProducao ? _ouNulo(_skus.text) : null,
      maoDeObra: usaProducao ? _paraInt(_maoDeObra.text) : null,
      dimensoesCaixas:
          tipo == TipoSetor.estoque ? _ouNulo(_dimensoesCaixas.text) : null,
      peso: tipo == TipoSetor.estoque ? _ouNulo(_peso.text) : null,
      montagemPallets:
          tipo == TipoSetor.estoque ? _ouNulo(_montagemPallets.text) : null,
      outrasInformacoes: _ouNulo(_outras.text),
      criadoEm: widget.setor.criadoEm,
      atualizadoEm: DateTime.now(),
    );

    try {
      await _repository.atualizar(atualizado);
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

  Widget _campoTexto(
    TextEditingController controller,
    String rotulo, {
    String? dica,
    int minLines = 1,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: rotulo,
          hintText: dica,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
        minLines: minLines,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
      ),
    );
  }

  Widget _campoMaoDeObra() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: _maoDeObra,
        decoration: const InputDecoration(
          labelText: 'Mão de obra (qtd. de pessoas)',
          border: OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        validator: (value) {
          if (value == null || value.trim().isEmpty) return null;
          if (int.tryParse(value.trim()) == null) {
            return 'Informe um número inteiro.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipo = widget.setor.tipo;
    return Scaffold(
      appBar: AppBar(title: Text('Processo — ${tipo.rotulo}')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (tipo == TipoSetor.cozinha) ...[
              _campoTexto(_capacidade, 'Capacidade', dica: 'Ex.: 500 kg/h'),
              _campoTexto(_velocidade, 'Velocidade', dica: 'Ex.: 12 un/min'),
              _campoTexto(_skus, 'SKUs', dica: 'Ex.: códigos ou quantidade'),
              _campoMaoDeObra(),
            ] else if (tipo == TipoSetor.embalagem) ...[
              _campoTexto(_velocidade, 'Velocidade', dica: 'Ex.: 30 pct/min'),
              _campoTexto(_skus, 'SKUs', dica: 'Ex.: códigos ou quantidade'),
              _campoMaoDeObra(),
            ] else ...[
              _campoTexto(
                _dimensoesCaixas,
                'Dimensões das caixas',
                dica: 'Ex.: 40 x 30 x 25 cm',
              ),
              _campoTexto(_peso, 'Peso', dica: 'Ex.: 12 kg por caixa'),
              _campoTexto(
                _montagemPallets,
                'Montagem dos pallets',
                dica: 'Ex.: 8 caixas por camada, 5 camadas',
                minLines: 2,
                maxLines: 4,
              ),
            ],
            _campoTexto(
              _outras,
              'Outras informações',
              minLines: 3,
              maxLines: 6,
            ),
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
