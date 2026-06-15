// Compartilhamento/salvamento do arquivo exportado, por plataforma (importação
// condicional para não puxar `dart:io` na web nem APIs web no nativo).
//
// - Nativo (Android/iOS/desktop): grava um arquivo temporário e abre a folha
//   de compartilhamento (share_plus).
// - Web: dispara o download do arquivo no navegador.
export 'exportar_arquivo_web.dart'
    if (dart.library.io) 'exportar_arquivo_io.dart';
