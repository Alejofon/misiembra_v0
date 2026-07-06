import 'dart:convert';

Map<String, dynamic> parsePlanResponse(String rawResponse) {
  final sanitized = _sanitizeJson(rawResponse);
  return jsonDecode(sanitized) as Map<String, dynamic>;
}

String _sanitizeJson(String rawResponse) {
  final withoutCodeFence = rawResponse
      .replaceAll('```json', '')
      .replaceAll('```', '')
      .trim();

  final sanitized = withoutCodeFence.replaceAllMapped(
    RegExp(r':\s*(\d{1,3}(?:,\d{3})+(?:\.\d+)?)'),
    (match) {
      final value = match.group(1)!;
      return ': ${value.replaceAll(',', '')}';
    },
  );

  return sanitized;
}
