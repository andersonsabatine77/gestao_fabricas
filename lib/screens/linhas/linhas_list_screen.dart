import 'package:flutter/material.dart';

import '../../models/fabrica.dart';
import '../../models/linha.dart';
import '../../repositories/linha_repository.dart';
import 'linha_detalhe_screen.dart';
import 'linha_form_screen.dart';

/// Lista as linhas de uma fábrica.
///
/// Tocar numa linha abre o detalhe dela (abas Cozinha/Embalagem/Estoque).
/// Editar e apagar a linha ficam no menu (⋮) de cada item.
class LinhasListScreen extends StatefulWidget {
  const LinhasListScreen({super.key, required this.fabrica});

  final Fabrica fabrica;

  @override
  State<LinhasListScreen> createState() => _LinhasListScreenState();
}

class _LinhasListScreenState extends State<LinhasListScreen> {
  final LinhaRepository _repository = LinhaRepository();
  late Future<List<Linha>> _futureLinhas;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  void _carregar() {
    setState(() {
      _futureLinhas = _repository.listarPorFabrica(widget.fabrica.id);
    });
  }

  Future<void> _abrirDetalhe(Linha linha) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LinhaDetalheScreen(linha: linha)),
    );
    _carregar();
  }

  Future<void> _abrirFormulario([Linha? linha]) async {
    final salvou = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => LinhaFormScreen(fabrica: widget.fabrica, linha: linha),
      ),
    );
    if (salvou == true) {
      _carregar();
    }
  }

  Future<void> _confirmarExclusao(Linha linha) async {
    final confirmou = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar linha'),
        content: Text(
          'Deseja apagar "${linha.nome}"? Os setores e equipamentos vinculados '
          'também serão apagados. Esta ação não pode ser desfeita.',
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

    await _repository.apagar(linha.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Linha "${linha.nome}" apagada.')),
    );
    _carregar();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Linhas'),
            Text(
              widget.fabrica.nome,
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async => _carregar(),
        child: FutureBuilder<List<Linha>>(
          future: _futureLinhas,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return _MensagemCentralizada(
                'Erro ao carregar as linhas:\n${snapshot.error}',
              );
            }
            final linhas = snapshot.data ?? const <Linha>[];
            if (linhas.isEmpty) {
              return const _EstadoVazio();
            }
            return ListView.separated(
              itemCount: linhas.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final linha = linhas[index];
                final temObservacoes = linha.observacoes != null &&
                    linha.observacoes!.isNotEmpty;
                return ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.linear_scale)),
                  title: Text(linha.nome),
                  subtitle: temObservacoes
                      ? Text(
                          linha.observacoes!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      : null,
                  onTap: () => _abrirDetalhe(linha),
                  trailing: PopupMenuButton<_AcaoLinha>(
                    tooltip: 'Mais ações',
                    onSelected: (acao) {
                      switch (acao) {
                        case _AcaoLinha.editar:
                          _abrirFormulario(linha);
                        case _AcaoLinha.apagar:
                          _confirmarExclusao(linha);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: _AcaoLinha.editar,
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: _AcaoLinha.apagar,
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
        label: const Text('Nova linha'),
      ),
    );
  }
}

enum _AcaoLinha { editar, apagar }

class _EstadoVazio extends StatelessWidget {
  const _EstadoVazio();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.25),
        Icon(Icons.linear_scale, size: 72, color: theme.colorScheme.outline),
        const SizedBox(height: 16),
        Center(
          child: Text(
            'Nenhuma linha cadastrada',
            style: theme.textTheme.titleMedium,
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'Toque em "Nova linha" para começar.',
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
