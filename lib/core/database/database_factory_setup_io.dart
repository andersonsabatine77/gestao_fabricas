import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Configura o backend do SQLite em plataformas nativas.
///
/// - **Android / iOS**: usam o `sqflite` padrão; nenhuma configuração é
///   necessária (este é o alvo principal do app).
/// - **Windows / Linux / macOS**: usam o backend FFI (`sqflite_common_ffi`),
///   útil para testar o app no desktop durante o desenvolvimento.
void configurarDatabaseFactory() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.macOS:
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    case TargetPlatform.android:
    case TargetPlatform.iOS:
    case TargetPlatform.fuchsia:
      // sqflite padrão — nada a fazer.
      break;
  }
}
