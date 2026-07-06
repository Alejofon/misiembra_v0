import 'package:flutter_test/flutter_test.dart';
import 'package:misiembra_v0/utils/number_format.dart';

void main() {
  test('formats whole numbers with dots for thousands and millions', () {
    expect(formatNumberWithDots('1500000'), '1.500.000');
    expect(formatNumberWithDots('1000000000'), '1.000.000.000');
    expect(formatNumberWithDots('1234'), '1.234');
    expect(formatNumberWithDots(''), '');
  });
}
