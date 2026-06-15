// Teste de fumaça (smoke test) básico do app.
//
// Verifica apenas que o app constrói e exibe a tela inicial de fábricas.
// A lista em si depende do SQLite (plugin), indisponível no ambiente de teste
// de widget, então não exercitamos o carregamento de dados aqui.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:gestao_fabricas/main.dart';

void main() {
  testWidgets('Tela inicial exibe o título "Fábricas"', (tester) async {
    await tester.pumpWidget(GestaoFabricasApp());

    expect(find.text('Fábricas'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Nova fábrica'),
        findsOneWidget);
  });
}
