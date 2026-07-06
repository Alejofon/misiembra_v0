
import 'package:flutter_test/flutter_test.dart';
import 'package:misiembra_v0/services/plan_response_parser.dart';

void main() {
  test('parses numeric JSON values with thousands separators', () {
    const input = '''
    {
      "rentabilidad": {
        "numero_plantas_estimadas": 16,000,
        "ganancia_estimada_por_cosecha": "16,000 COP"
      },
      "siembra_estimada": {
        "numero_plantas_estimadas": 8,500
      }
    }
    ''';

    final parsed = parsePlanResponse(input);

    expect(parsed['rentabilidad']['numero_plantas_estimadas'], 16000);
    expect(parsed['siembra_estimada']['numero_plantas_estimadas'], 8500);
    expect(parsed['rentabilidad']['ganancia_estimada_por_cosecha'], '16,000 COP');
  });
}
