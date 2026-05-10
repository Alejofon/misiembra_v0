// lib/prompts/prompt_base.dart

abstract class PromptBase {
  /// Limpia la respuesta de la IA eliminando markdown y texto adicional
  static String cleanResponse(String rawResponse) {
    String cleaned = rawResponse.trim();
    
    // Eliminar bloques de código markdown
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.replaceAll('```json', '');
    }
    if (cleaned.startsWith('```')) {
      cleaned = cleaned.replaceAll('```', '');
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    
    // Encontrar el primer { y el último }
    final startIndex = cleaned.indexOf('{');
    final endIndex = cleaned.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
      cleaned = cleaned.substring(startIndex, endIndex + 1);
    }
    
    // Eliminar comas finales
    cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}');
    cleaned = cleaned.replaceAll(RegExp(r',\s*]'), ']');
    
    return cleaned;
  }
  
  /// Valida que la respuesta de la IA (para opciones) sea una lista válida de cultivos
  static List<String> parseOpcionesResponse(String rawResponse) {
    final cleaned = rawResponse.trim();
    
    return cleaned
        .split('\n')
        .where((linea) => linea.trim().isNotEmpty)
        .map((linea) => linea
            .replaceAll(RegExp(r'^[\d\-\.\)]\s*'), '')
            .replaceAll(RegExp(r'^[\*\-]\s*'), '')
            .trim())
        .where((nombre) => nombre.isNotEmpty)
        .toList();
  }
}