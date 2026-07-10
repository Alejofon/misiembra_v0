// Capturas de la app REAL (rama main) para las figuras del documento:
//   Fig 11  HomePage con presupuesto/área/tipo de terreno diligenciados.
//   Fig 12  OptionsPage con las 5 opciones de /opciones-cultivo.
//   Fig 13/14  ProjectDetailPage — pestaña Rentabilidad.
//   Fig 15  pestaña Tiempos.  Fig 16  pestaña Plagas.  Fig 17  pestaña Proveedores.
//   Fig 18  HistoryPage con un análisis guardado.
//
// Ejecutar (simulador arrancado):
//   flutter drive --driver=test_driver/screenshot_driver.dart \
//     --target=integration_test/fig_app_real_test.dart -d <simulador>
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:misiembra_v0/screens/home_page.dart';
import 'package:misiembra_v0/screens/options_page.dart';
import 'package:misiembra_v0/screens/project_detail_page.dart';
import 'package:misiembra_v0/screens/history_page.dart';

const _depto = 'CUNDINAMARCA';
const _muni = 'TOCANCIPA';
const _lat = 5.0573;
const _lon = -73.9116;

Future<void> _esperarSinLoader(WidgetTester tester,
    {Duration timeout = const Duration(seconds: 90)}) async {
  final fin = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(fin)) {
    await tester.pump(const Duration(milliseconds: 500));
    if (find.byType(CircularProgressIndicator).evaluate().isEmpty) {
      await tester.pump(const Duration(milliseconds: 400));
      return;
    }
  }
}

Future<void> _cap(IntegrationTestWidgetsFlutterBinding b, WidgetTester t, String name) async {
  await b.convertFlutterSurfaceToImage();
  await t.pump(const Duration(milliseconds: 300));
  await b.takeScreenshot(name);
}

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  MaterialApp _app(Widget home) =>
      MaterialApp(debugShowCheckedModeBanner: false, home: home);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('Fig 11 — HomePage con formulario diligenciado', (tester) async {
    await tester.pumpWidget(_app(const HomePage()));
    await tester.pumpAndSettle();
    final campos = find.byType(TextField);
    await tester.enterText(campos.at(0), '12000000'); // presupuesto
    await tester.enterText(campos.at(1), '10000'); // área
    await tester.pumpAndSettle();
    await _cap(binding, tester, 'fig11_home_formulario');
  });

  testWidgets('Fig 12 — OptionsPage: opciones de siembra', (tester) async {
    await tester.pumpWidget(_app(const OptionsPage(
      presupuesto: '12000000', area: '10000', unidad: 'Metros cuadrados',
      tipoTerreno: 'plano', departamento: _depto, municipio: _muni,
      lat: _lat, lon: _lon,
    )));
    await tester.pump();
    await _esperarSinLoader(tester);
    await _cap(binding, tester, 'fig12_opciones');
  });

  testWidgets('Fig 13-17 — ProjectDetailPage y sus pestañas', (tester) async {
    await tester.pumpWidget(_app(const ProjectDetailPage(
      cultivo: 'Zanahoria', zona: 'Tocancipá, Cundinamarca',
      presupuesto: '12000000', area: '10000', unidad: 'Metros cuadrados',
      departamento: _depto, municipio: _muni, tipoTerreno: 'plano',
      lat: _lat, lon: _lon,
    )));
    await tester.pump();
    await _esperarSinLoader(tester, timeout: const Duration(seconds: 120));
    await _cap(binding, tester, 'fig13_14_plan_rentabilidad');

    for (final par in const [
      ['Tiempos', 'fig15_plan_tiempos'],
      ['Plagas', 'fig16_plan_plagas'],
      ['Proveedores', 'fig17_plan_proveedores'],
    ]) {
      final tab = find.text(par[0]);
      if (tab.evaluate().isNotEmpty) {
        await tester.tap(tab.first);
        await tester.pumpAndSettle(const Duration(seconds: 1));
        await _cap(binding, tester, par[1]);
      }
    }
  });

  testWidgets('Fig 18 — HistoryPage con un análisis guardado', (tester) async {
    final registro = {
      'cultivo': 'Zanahoria',
      'departamento': 'Cundinamarca',
      'municipio': 'Tocancipá',
      'presupuesto': '12000000',
      'area': '10000',
      'unidad': 'Metros cuadrados',
      'fecha': DateTime.now().toIso8601String(),
    };
    SharedPreferences.setMockInitialValues({'historial': [jsonEncode(registro)]});
    await tester.pumpWidget(_app(const HistoryPage()));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    await _cap(binding, tester, 'fig18_historial');
  });
}
