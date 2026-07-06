String formatNumberWithDots(String input) {
  if (input.isEmpty) return '';

  final digitsOnly = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digitsOnly.isEmpty) return '';

  final buffer = StringBuffer();
  final chars = digitsOnly.split('').reversed.toList();

  for (var i = 0; i < chars.length; i++) {
    if (i != 0 && i % 3 == 0) {
      buffer.write('.');
    }
    buffer.write(chars[i]);
  }

  return buffer.toString().split('').reversed.join();
}
