import 'package:flutter/material.dart';

import '../../models/linha.dart';
import '../../models/setor.dart';
import '../../repositories/setor_repository.dart';
import '../setores/setor_tab_view.dart';

/// Detalhe de uma linha: mostra as 3 abas fixas (Cozinha, Embalagem, Estoque),
/// cada uma com seus dados de processo e seus equipamentos.
class LinhaDetalheScreen extends StatefulWidget {
  const LinhaDetalheScreen({super.key, required this.linha});

  final Linha linha;

  @override
  State<LinhaDetalheScreen> createState() => _LinhaDetalheScreenState();
}

class _LinhaDetalheScreenState extends State<LinhaDetalheScreen> {
  final SetorRepository _repository = SetorRepository();
  late Future<List<Setor>> _futureSetores;

  @override
  void initState() {
    super.initState();
    _futureSetores = _carregarSetores();
  }

  Future<List<Setor>> _carregarSetores() async {
    // Garante os 3 setores (cobre dados importados/incompletos) e os lista.
    await _repository.garantirSetores(widget.linha.id);
    return _repository.listarPorLinha(widget.linha.id);
  }

  IconData _iconeTipo(TipoSetor tipo) {
    switch (tipo) {
      case TipoSetor.cozinha:
        return Icons.soup_kitchen;
      case TipoSetor.embalagem:
        return Icons.inventory_2;
      case TipoSetor.estoque:
        return Icons.warehouse;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<List<Setor>>(
      future: _futureSetores,
      builder: (context, snapshot) {
        final appBarTitle = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.linha.nome),
            Text(
              'Linha de produção',
              style: theme.textTheme.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: appBarTitle),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: appBarTitle),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Erro ao carregar os setores:\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final setores = snapshot.data ?? const <Setor>[];
        return DefaultTabController(
          length: setores.length,
          child: Scaffold(
            appBar: AppBar(
              title: appBarTitle,
              bottom: TabBar(
                tabs: [
                  for (final setor in setores)
                    Tab(
                      icon: Icon(_iconeTipo(setor.tipo)),
                      text: setor.tipo.rotulo,
                    ),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                for (final setor in setores) SetorTabView(setor: setor),
              ],
            ),
          ),
        );
      },
    );
  }
}
