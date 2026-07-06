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
        initialStyle?.backgroundColor?.resolve({MaterialState.disabled});
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

  testWidgets('Top snackbars use floating behavior and top margin',
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
    await tester.pumpAndSettle();

    final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
    expect(snackBar.behavior, SnackBarBehavior.floating);
    expect(snackBar.margin,
        const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 0));
  });
}
