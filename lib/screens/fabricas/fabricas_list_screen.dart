import 'package:flutter/material.dart';

import '../../core/theme/theme_controller.dart';
import '../../models/fabrica.dart';
import '../../repositories/fabrica_repository.dart';
import '../../repositories/linha_repository.dart';
import '../configuracoes/configuracoes_screen.dart';
import '../linhas/linhas_list_screen.dart';
import 'fabrica_form_screen.dart';

/// Tela inicial: lista as fábricas cadastradas.
///
/// Tocar numa fábrica entra nas suas linhas (drill-down). Editar e apagar a
/// fábrica ficam no menu (⋮) de cada item.
class FabricasListScreen extends StatefulWidget {
  const FabricasListScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<FabricasListScreen> createState() => _FabricasListScreenState();
}

class _FabricasListScreenState extends State<FabricasListScreen> {
  final FabricaRepository _fabricaRepository = FabricaRepository();
  final LinhaRepository _linhaRepository = LinhaRepository();
  late Future<_FabricasView> _future;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _future = _buscar();
    });
  }

  Future<_FabricasView> _buscar() async {
    final fabricas = await _fabricaRepository.listar();
    final contagemLinhas = await _linhaRepository.contagemPorFabrica();
    return _FabricasView(fabricas: fabricas, contagemLinhas: contagemLinhas);
  }

  Future<void> _abrirLinhas(Fabrica fabrica) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LinhasListScreen(fabrica: fabrica)),
    );
    // Ao voltar, recarrega para refletir alterações na contagem de linhas.
    _carregar();
  }

  Future<void> _abrirFormulario([Fabrica? fabrica]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => FabricaFormScreen(fabrica: fabrica),
      ),
    );
    if (salvou == true) {
      _carregar();
    }
  }

  Future<void> _confirmarExclusao(Fabrica fabrica) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar fábrica'),
        content: Text(
          'Deseja apagar "${fabrica.nome}"? Todas as linhas vinculadas '
          'também serão apagadas. Esta ação não pode ser desfeita.',
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

    await _fabricaRepository.apagar(fabrica.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Fábrica "${fabrica.nome}" apagada.')),
    );
    _carregar();
  }

  String _subtitulo(Fabrica fabrica, int qtdLinhas) {
    final partes = <String>[];
    if (fabrica.localizacao != null && fabrica.localizacao!.isNotEmpty) {
      partes.add(fabrica.localizacao!);
    }
    partes.add(qtdLinhas == 1 ? '1 linha' : '$qtdLinhas linhas');
    return partes.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fábricas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Configurações',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ConfiguracoesScreen(
                    themeController: widget.themeController,
                  ),
                ),
              );
              // Ao voltar, recarrega (os dados podem ter mudado por importação).
              if (mounted) _carregar();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregar(),
        child: FutureBuilder<_FabricasView>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MensagemCentralizada(
                'Erro ao carregar as fábricas:\n${snapshot.error}',
              );
            }
            final dados = snapshot.data;
            final fabricas = dados?.fabricas ?? const <Fabrica>[];
            if (fabricas.isEmpty) {
              return const _EstadoVazio();
            }
            return ListView.separated(
              itemCount: fabricas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final fabrica = fabricas[index];
                final qtdLinhas = dados?.contagemLinhas[fabrica.id] ?? 0;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.factory)),
                  title: Text(fabrica.nome),
                  subtitle: Text(_subtitulo(fabrica, qtdLinhas)),
                  onTap: () => _abrirLinhas(fabrica),
                  trailing: PopupMenuButton<_AcaoFabrica>(
                    tooltip: 'Mais ações',
                    onSelected: (acao) {
                      switch (acao) {
                        case _AcaoFabrica.editar:
                          _abrirFormulario(fabrica);
                        case _AcaoFabrica.apagar:
                          _confirmarExclusao(fabrica);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _AcaoFabrica.editar,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _AcaoFabrica.apagar,
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Apagar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        icon: const Icon(Icons.add),
        label: const Text('Nova fábrica'),
      ),
    );
  }
}

enum _AcaoFabrica { editar, apagar }

/// Agrupa os dados necessários para montar a lista numa única carga.
class _FabricasView {
  const _FabricasView({required this.fabricas, required this.contagemLinhas});

  final List<Fabrica> fabricas;

  /// Quantidade de linhas por id de fábrica.
  final Map<String, int> contagemLinhas;
}

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Dentro de um ListView para que o "pull to refresh" funcione mesmo vazio.
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(
          Icons.factory_outlined,
          size: 72,
          color: theme.colorScheme.outline,
        ),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Nenhuma fábrica cadastrada',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Toque em "Nova fábrica" para começar.',
            style: theme.textTheme.bodySmall,
          ),
        ),
      ],
    );
  }
}

class _MensagemCentralizada extends StatelessWidget {
  const _MensagemCentralizada(this.texto);

  final String texto;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(texto, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}
