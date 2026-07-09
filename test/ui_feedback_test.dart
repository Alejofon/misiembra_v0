import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misiembra_v0/screens/home_page.dart';
import 'package:misiembra_v0/utils/snackbar_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'HomePage shows the recommendations button with green active styling once the form is complete',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomePage()));
    await tester.pumpAndSettle();

    final buttonFinder =
        find.widgetWithText(ElevatedButton, 'Consultar recomendaciones');
    expect(buttonFinder, findsOneWidget);

    final initialButton = tester.widget<ElevatedButton>(buttonFinder);
    final initialStyle = initialButton.style;
    final initialBackground =
        initialStyle?.backgroundColor?.resolve({WidgetState.disabled});
    expect(initialBackground, isNotNull);
    expect(initialButton.onPressed, isNull);

    await tester.enterText(find.byType(TextField).at(0), '1000000');
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.pumpAndSettle();

    final enabledButton = tester.widget<ElevatedButton>(buttonFinder);
    expect(enabledButton.onPressed, isNull);

    final enabledBackground = enabledButton.style?.backgroundColor?.resolve({});
    expect(enabledBackground, isNotNull);
  });

  testWidgets(
      'showTopSnackBar muestra un aviso en la parte superior y ya no usa SnackBar',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return Center(
                child: ElevatedButton(
                  onPressed: () {
                    showTopSnackBar(context, 'Mensaje de prueba');
                  },
                  child: const Text('Mostrar'),
                ),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mostrar'));
    await tester.pump(); // inserta el OverlayEntry
    await tester.pump(const Duration(milliseconds: 300)); // completa la animación de entrada

    // El aviso ahora es un toast propio basado en Overlay (arriba), no un
    // SnackBar de Flutter (que Flutter ancla siempre abajo, tapando los botones).
    expect(find.text('Mensaje de prueba'), findsOneWidget);
    expect(find.byType(SnackBar), findsNothing);

    // Debe aparecer en la mitad SUPERIOR de la pantalla.
    final pantalla = tester.getSize(find.byType(MaterialApp));
    final centroAviso = tester.getCenter(find.text('Mensaje de prueba'));
    expect(centroAviso.dy, lessThan(pantalla.height / 2));

    // Dejar que se auto-cierre (timer de 3 s + animación de salida) para no
    // dejar temporizadores pendientes en el test.
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Mensaje de prueba'), findsNothing);
  });
}
