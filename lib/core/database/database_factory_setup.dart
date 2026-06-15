// Seleção do backend do SQLite por plataforma, via importação condicional.
//
// - Em plataformas nativas (Android, iOS e desktop) usa a implementação de
//   database_factory_setup_io.dart.
// - Na web usa a implementação WASM de database_factory_setup_web.dart.
//
// Isso evita que o código da web importe `dart:io`/FFI (e vice-versa),
// que não compilam fora da sua plataforma.
export 'database_factory_setup_web.dart'
    if (dart.library.io) 'database_factory_setup_io.dart';
