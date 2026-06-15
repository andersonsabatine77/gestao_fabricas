import 'package:flutter/material.dart';

import '../../models/equipamento.dart';
import '../../models/setor.dart';
import '../../repositories/equipamento_repository.dart';
import '../../repositories/setor_repository.dart';
import '../equipamentos/equipamento_form_screen.dart';
import 'setor_form_screen.dart';

/// Conteúdo de uma aba (setor): os dados de processo daquele setor e a lista
/// de equipamentos dele.
class SetorTabView extends StatefulWidget {
  const SetorTabView({super.key, required this.setor});

  final Setor setor;

  @override
  State<SetorTabView> createState() => _SetorTabViewState();
}

class _SetorTabViewState extends State<SetorTabView>
    with AutomaticKeepAliveClientMixin {
  final SetorRepository _setorRepository = SetorRepository();
  final EquipamentoRepository _equipamentoRepository = EquipamentoRepository();

  late Setor _setor;
  late Future<List<Equipamento>> _futureEquipamentos;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setor = widget.setor;
    _carregarEquipamentos();
  }

  void _carregarEquipamentos() {
    setState(() {
      _futureEquipamentos = _equipamentoRepository.listarPorSetor(_setor.id);
    });
  }

  Future<void> _editarProcesso() async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => SetorFormScreen(setor: _setor)),
    );
    if (salvou == true) {
      final atualizado = await _setorRepository.buscarPorId(_setor.id);
      if (atualizado != null && mounted) {
        setState(() => _setor = atualizado);
      }
    }
  }

  Future<void> _abrirEquipamento([Equipamento? equipamento]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            EquipamentoFormScreen(setor: _setor, equipamento: equipamento),
      ),
    );
    if (salvou == true) {
      _carregarEquipamentos();
    }
  }

  Future<void> _confirmarExclusao(Equipamento equipamento) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar equipamento'),
        content: Text(
          'Deseja apagar "${equipamento.nome}"? Esta ação não pode ser '
          'desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmou != true) return;
    await _equipamentoRepository.apagar(equipamento.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Equipamento "${equipamento.nome}" apagado.')),
    );
    _carregarEquipamentos();
  }

  /// Pares (rótulo, valor) dos campos de processo preenchidos, conforme o tipo.
  List<(String, String)> _camposProcesso() {
    final campos = <(String, String)>[];
    void add(String rotulo, String? valor) {
      if (valor != null && valor.trim().isNotEmpty) campos.add((rotulo, valor));
    }

    switch (_setor.tipo) {
      case TipoSetor.cozinha:
        add('Capacidade', _setor.capacidade);
        add('Velocidade', _setor.velocidade);
        add('SKUs', _setor.skus);
        add('Mão de obra', _setor.maoDeObra?.toString());
      case TipoSetor.embalagem:
        add('Velocidade', _setor.velocidade);
        add('SKUs', _setor.skus);
        add('Mão de obra', _setor.maoDeObra?.toString());
      case TipoSetor.estoque:
        add('Dimensões das caixas', _setor.dimensoesCaixas);
        add('Peso', _setor.peso);
        add('Montagem dos pallets', _setor.montagemPallets);
    }
    add('Outras informações', _setor.outrasInformacoes);
    return campos;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);
    final campos = _camposProcesso();

    return RefreshIndicator(
      onRefresh: () async => _carregarEquipamentos(),
      child: FutureBuilder<List<Equipamento>>(
        future: _futureEquipamentos,
        builder: (context, snapshot) {
          final equipamentos = snapshot.data ?? const <Equipamento>[];
          final carregando =
              snapshot.connectionState == ConnectionState.waiting;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ----- Dados do processo -----
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Dados do processo',
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _editarProcesso,
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Editar'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (campos.isEmpty)
                        Text(
                          'Sem dados de processo. Toque em "Editar" para '
                          'preencher.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.outline,
                          ),
                        )
                      else
                        for (final (rotulo, valor) in campos)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rotulo,
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                                Text(valor, style: theme.textTheme.bodyLarge),
                              ],
                            ),
                          ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ----- Equipamentos -----
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Equipamentos (${equipamentos.length})',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _abrirEquipamento(),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Adicionar'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (carregando)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (equipamentos.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Nenhum equipamento cadastrado neste setor.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                )
              else
                for (final equipamento in equipamentos)
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    child: ListTile(
                      leading: const CircleAvatar(
                        child: Icon(Icons.precision_manufacturing),
                      ),
                      title: Text(equipamento.nome),
                      subtitle: _subtituloEquipamento(equipamento) == null
                          ? null
                          : Text(_subtituloEquipamento(equipamento)!),
                      onTap: () => _abrirEquipamento(equipamento),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Apagar',
                        onPressed: () => _confirmarExclusao(equipamento),
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }

  String? _subtituloEquipamento(Equipamento e) {
    final partes = <String>[];
    if (e.fabricante != null && e.fabricante!.isNotEmpty) partes.add(e.fabricante!);
    if (e.modelo != null && e.modelo!.isNotEmpty) partes.add(e.modelo!);
    if (partes.isEmpty) return null;
    return partes.join(' • ');
  }
}
