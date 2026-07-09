// Smoke test de arranque de la app MiSiembra.
//
// Verifica que la aplicación se construye y muestra su pantalla inicial
// (StartPage) sin lanzar excepciones. Reemplaza el test "Counter increments"
// que venía por defecto en el andamiaje de Flutter y que ya no aplica.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misiembra_v0/main.dart';

void main() {
  testWidgets('La app arranca y muestra la pantalla inicial sin errores',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // La app construye un MaterialApp y no lanza excepciones al iniciar
    // (StartPage no dispara geolocalización en initState, solo por acción).
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
