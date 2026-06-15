import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../core/backup/backup_service.dart';
import '../../core/theme/theme_controller.dart';
import 'exportar_screen.dart';

/// Tela de configurações: tema e importação/exportação de dados.
class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final BackupService _backup = BackupService();
  bool _importando = false;

  Future<void> _importar() async {
    // 1) Escolher o arquivo.
    final FilePickerResult? resultado;
    try {
      resultado = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
    } catch (e) {
      _avisar('Não foi possível abrir o seletor de arquivos: $e');
      return;
    }
    if (resultado == null) return; // cancelado

    final Uint8List bytes;
    try {
      bytes = await resultado.files.single.readAsBytes();
    } catch (e) {
      _avisar('Não foi possível ler o arquivo selecionado: $e');
      return;
    }

    // 2) Escolher o modo (mesclar / sobrescrever).
    final modo = await _escolherModo();
    if (modo == null) return;

    // 3) Aplicar.
    setState(() => _importando = true);
    try {
      final conteudo = utf8.decode(bytes);
      final res = await _backup.importarJson(conteudo, modo: modo);
      _avisar(
        'Importado: ${res.fabricas} fábrica(s), ${res.linhas} linha(s), '
        '${res.equipamentos} equipamento(s).',
      );
    } on FormatException catch (e) {
      _avisar(e.message);
    } catch (e) {
      _avisar('Falha ao importar: $e');
    } finally {
      if (mounted) setState(() => _importando = false);
    }
  }

  Future<ModoImport?> _escolherModo() {
    return showDialog<ModoImport>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Como importar?'),
        content: const Text(
          'Mesclar: mantém os dados atuais e adiciona/atualiza com o arquivo.\n\n'
          'Sobrescrever: APAGA todos os dados atuais e deixa apenas o conteúdo '
          'do arquivo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(ModoImport.mesclar),
            child: const Text('Mesclar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(ModoImport.sobrescrever),
            child: const Text('Sobrescrever'),
          ),
        ],
      ),
    );
  }

  void _avisar(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensagem)));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ----- Tema -----
          Text('Tema', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: widget.themeController,
            builder: (context, _) {
              return SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                  ),
                  ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
                  ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
                ],
                selected: {widget.themeController.modo},
                showSelectedIcon: false,
                onSelectionChanged: (s) =>
                    widget.themeController.definir(s.first),
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            '"Sistema" segue o tema do aparelho.',
            style: theme.textTheme.bodySmall,
          ),

          const Divider(height: 40),

          // ----- Dados -----
          Text('Dados', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.ios_share),
            title: const Text('Exportar dados'),
            subtitle: const Text('Gerar um arquivo (tudo, uma fábrica ou linha)'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const ExportarScreen()),
            ),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: _importando
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.file_open_outlined),
            title: const Text('Importar dados'),
            subtitle: const Text('Ler um arquivo e mesclar ou sobrescrever'),
            onTap: _importando ? null : _importar,
          ),
        ],
      ),
    );
  }
}
