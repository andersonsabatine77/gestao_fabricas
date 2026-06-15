import 'package:flutter/material.dart';

import 'core/database/database_factory_setup.dart';
import 'core/theme/theme_controller.dart';
import 'screens/fabricas/fabricas_list_screen.dart';

Future<void> main() async {
  // Garante que os bindings estão prontos antes de qualquer acesso a plugins
  // (SQLite, preferências). A conexão com o banco é aberta de forma preguiçosa.
  WidgetsFlutterBinding.ensureInitialized();
  // Escolhe o backend do SQLite conforme a plataforma (mobile, desktop ou web).
  configurarDatabaseFactory();
  // Carrega a preferência de tema salva antes de montar o app.
  final themeController = ThemeController();
  await themeController.carregar();
  runApp(GestaoFabricasApp(themeController: themeController));
}

class GestaoFabricasApp extends StatelessWidget {
  GestaoFabricasApp({super.key, ThemeController? themeController})
      : themeController = themeController ?? ThemeController();

  final ThemeController themeController;

  ThemeData _tema(Brightness brilho) {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.indigo,
        brightness: brilho,
      ),
      useMaterial3: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeController,
      builder: (context, _) {
        return MaterialApp(
          title: 'Gestão de Fábricas',
          debugShowCheckedModeBanner: false,
          theme: _tema(Brightness.light),
          darkTheme: _tema(Brightness.dark),
          themeMode: themeController.modo,
          home: FabricasListScreen(themeController: themeController),
        );
      },
    );
  }
}
