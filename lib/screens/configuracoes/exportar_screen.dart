import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/backup/backup_service.dart';
import '../../models/fabrica.dart';
import '../../models/linha.dart';
import '../../repositories/fabrica_repository.dart';
import '../../repositories/linha_repository.dart';

/// Tela para exportar dados: escolhe o escopo (tudo / uma fábrica / uma linha)
/// e gera o arquivo JSON para compartilhar.
class ExportarScreen extends StatefulWidget {
  const ExportarScreen({super.key});

  @override
  State<ExportarScreen> createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  final FabricaRepository _fabricaRepository = FabricaRepository();
  final LinhaRepository _linhaRepository = LinhaRepository();
  final BackupService _backup = BackupService();

  List<Fabrica> _fabricas = const [];
  List<Linha> _linhas = const [];
  bool _carregando = true;

  EscopoExport _escopo = EscopoExport.tudo;
  Fabrica? _fabrica;
  Linha? _linha;

  bool _exportando = false;

  @override
  void initState() {
    super.initState();
    _carregarFabricas();
  }

  Future<void> _carregarFabricas() async {
    final fabricas = await _fabricaRepository.listar();
    if (!mounted) return;
    setState(() {
      _fabricas = fabricas;
      _carregando = false;
    });
  }

  Future<void> _aoMudarFabrica(Fabrica? fabrica) async {
    setState(() {
      _fabrica = fabrica;
      _linha = null;
      _linhas = const [];
    });
    if (fabrica != null && _escopo == EscopoExport.linha) {
      final linhas = await _linhaRepository.listarPorFabrica(fabrica.id);
      if (!mounted) return;
      setState(() => _linhas = linhas);
    }
  }

  bool get _podeExportar {
    switch (_escopo) {
      case EscopoExport.tudo:
        return true;
      case EscopoExport.fabrica:
        return _fabrica != null;
      case EscopoExport.linha:
        return _linha != null;
    }
  }

  String _carimboHora() {
    final agora = DateTime.now();
    String d2(int n) => n.toString().padLeft(2, '0');
    return '${agora.year}${d2(agora.month)}${d2(agora.day)}_'
        '${d2(agora.hour)}${d2(agora.minute)}${d2(agora.second)}';
  }

  Future<void> _exportar() async {
    setState(() => _exportando = true);
    try {
      final json = await _backup.exportarJson(
        escopo: _escopo,
        fabricaId: _fabrica?.id,
        linhaId: _linha?.id,
      );
      final nome = 'gestao_fabricas_${_escopo.name}_${_carimboHora()}.json';
      final caminho = await FilePicker.saveFile(
        dialogTitle: 'Salvar arquivo de dados',
        fileName: nome,
        type: FileType.custom,
        allowedExtensions: ['json'],
        bytes: Uint8List.fromList(utf8.encode(json)),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            caminho == null
                ? 'Exportação cancelada.'
                : 'Dados exportados com sucesso.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Não foi possível exportar: $e')),
      );
    } finally {
      if (mounted) setState(() => _exportando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Exportar dados')),
      body: _carregando
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('O que exportar', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                SegmentedButton<EscopoExport>(
                  segments: const [
                    ButtonSegment(
                      value: EscopoExport.tudo,
                      label: Text('Tudo'),
                    ),
                    ButtonSegment(
                      value: EscopoExport.fabrica,
                      label: Text('Fábrica'),
                    ),
                    ButtonSegment(
                      value: EscopoExport.linha,
                      label: Text('Linha'),
                    ),
                  ],
                  selected: {_escopo},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) {
                    setState(() {
                      _escopo = s.first;
                      _linha = null;
                    });
                    if (_escopo == EscopoExport.linha && _fabrica != null) {
                      _aoMudarFabrica(_fabrica);
                    }
                  },
                ),
                const SizedBox(height: 24),
                if (_escopo != EscopoExport.tudo) ...[
                  if (_fabricas.isEmpty)
                    Text(
                      'Nenhuma fábrica cadastrada para exportar.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fábrica',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Fabrica>(
                          isExpanded: true,
                          value: _fabrica,
                          hint: const Text('Selecione a fábrica'),
                          items: [
                            for (final f in _fabricas)
                              DropdownMenuItem(value: f, child: Text(f.nome)),
                          ],
                          onChanged: _aoMudarFabrica,
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                if (_escopo == EscopoExport.linha && _fabrica != null) ...[
                  if (_linhas.isEmpty)
                    Text(
                      'Esta fábrica não tem linhas para exportar.',
                      style: theme.textTheme.bodyMedium,
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Linha',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<Linha>(
                          isExpanded: true,
                          value: _linha,
                          hint: const Text('Selecione a linha'),
                          items: [
                            for (final l in _linhas)
                              DropdownMenuItem(value: l, child: Text(l.nome)),
                          ],
                          onChanged: (l) => setState(() => _linha = l),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed:
                      (_podeExportar && !_exportando) ? _exportar : null,
                  icon: _exportando
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.ios_share),
                  label: Text(_exportando ? 'Gerando...' : 'Exportar'),
                ),
              ],
            ),
    );
  }
}
