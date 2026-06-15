import 'dart:js_interop';

import 'package:web/web.dart' as web;

/// Dispara o download do [conteudo] como arquivo no navegador.
/// [assunto] não é usado na web.
Future<void> compartilharTexto({
  required String conteudo,
  required String nomeArquivo,
  String? assunto,
}) async {
  final partes = <JSAny>[conteudo.toJS].toJS;
  final blob = web.Blob(
    partes,
    web.BlobPropertyBag(type: 'application/json;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(blob);
  final ancora = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = url
    ..download = nomeArquivo
    ..style.display = 'none';
  web.document.body!.appendChild(ancora);
  ancora.click();
  ancora.remove();
  web.URL.revokeObjectURL(url);
}
