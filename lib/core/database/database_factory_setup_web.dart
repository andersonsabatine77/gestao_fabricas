import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Configura o backend do SQLite na web (implementação em WASM).
///
/// Requer que os arquivos de apoio tenham sido gerados uma vez com:
///   dart run sqflite_common_ffi_web:setup
/// (eles ficam em `web/sqlite3.wasm` e `web/sqflite_sw.js`).
void configurarDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
