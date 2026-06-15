import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Grava o [conteudo] num arquivo temporário e abre a folha de
/// compartilhamento do sistema (enviar por e-mail, salvar, WhatsApp, etc.).
Future<void> compartilharTexto({
  required String conteudo,
  required String nomeArquivo,
  String? assunto,
}) async {
  final diretorio = await getTemporaryDirectory();
  final caminho = '${diretorio.path}/$nomeArquivo';
  final arquivo = File(caminho);
  await arquivo.writeAsString(conteudo, encoding: utf8, flush: true);

  await Share.shareXFiles(
    [XFile(caminho, mimeType: 'application/json')],
    subject: assunto,
  );
}
