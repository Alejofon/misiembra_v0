// Driver de captura: guarda como PNG en capturas/ cada takeScreenshot() del
// test de integración. Uso:
//   flutter drive --driver=test_driver/screenshot_driver.dart \
//                 --target=integration_test/<archivo>.dart -d <simulador>
import 'dart:io';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  await integrationDriver(
    onScreenshot: (String name, List<int> bytes, [Map<String, Object?>? args]) async {
      final file = File('capturas/$name.png');
      file.parent.createSync(recursive: true);
      file.writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('📸 guardada capturas/$name.png (${bytes.length} bytes)');
      return true;
    },
  );
}
