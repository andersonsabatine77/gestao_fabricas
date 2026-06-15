import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controla o tema do app (claro / escuro / padrão do sistema) e persiste a
/// escolha do usuário com `shared_preferences`.
///
/// É um [ChangeNotifier]: a raiz do app escuta e reconstrói o [MaterialApp]
/// quando o tema muda.
class ThemeController extends ChangeNotifier {
  static const String _chave = 'tema';

  ThemeMode _modo = ThemeMode.system;
  ThemeMode get modo => _modo;

  /// Lê a preferência salva. Chame uma vez no `main()` antes do `runApp`.
  Future<void> carregar() async {
    final prefs = await SharedPreferences.getInstance();
    _modo = _porNome(prefs.getString(_chave));
    notifyListeners();
  }

  /// Define e salva o novo tema.
  Future<void> definir(ThemeMode modo) async {
    if (modo == _modo) return;
    _modo = modo;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_chave, modo.name);
  }

  ThemeMode _porNome(String? nome) {
    switch (nome) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
