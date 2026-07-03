import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiMiSiembraService {
  static const String _baseUrl = 'https://api-dane-micro.onrender.com';

  // ------------------------------------------------------------
  // Mapeo: departamento normalizado -> { capital, departamentoOficial }
  // Basado en el JSON proporcionado.
  // ------------------------------------------------------------
  static final Map<String, Map<String, String>> _departmentToCapital = () {
    // Datos originales (según el JSON del usuario)
    final List<Map<String, String>> rawMapping = [
      {"muni_nombre": "ARMENIA", "dept_nombre": "QUINDÍO"},
      {"muni_nombre": "BARRANQUILLA", "dept_nombre": "ATLÁNTICO"},
      {"muni_nombre": "BOGOTÁ, D.C.", "dept_nombre": "BOGOTÁ, D. C."},
      {"muni_nombre": "BOGOTÁ, D.C.", "dept_nombre": "BOGOTÁ, D.C."},
      {"muni_nombre": "BUCARAMANGA", "dept_nombre": "SANTANDER"},
      {"muni_nombre": "CALI", "dept_nombre": "VALLE DEL CAUCA"},
      {"muni_nombre": "CARTAGENA DE INDIAS", "dept_nombre": "BOLÍVAR"},
      {"muni_nombre": "CÚCUTA", "dept_nombre": "NORTE DE SANTANDER"},
      {"muni_nombre": "IBAGUÉ", "dept_nombre": "TOLIMA"},
      {"muni_nombre": "MANIZALES", "dept_nombre": "CALDAS"},
      {"muni_nombre": "MEDELLÍN", "dept_nombre": "ANTIOQUIA"},
      {"muni_nombre": "MONTERÍA", "dept_nombre": "CÓRDOBA"},
      {"muni_nombre": "NEIVA", "dept_nombre": "HUILA"},
      {"muni_nombre": "PASTO", "dept_nombre": "NARIÑO"},
      {"muni_nombre": "PEREIRA", "dept_nombre": "RISARALDA"},
      {"muni_nombre": "POPAYÁN", "dept_nombre": "CAUCA"},
      {"muni_nombre": "SAN JOSÉ DE CÚCUTA", "dept_nombre": "NORTE DE SANTANDER"},
      {"muni_nombre": "SANTA MARTA", "dept_nombre": "MAGDALENA"},
      {"muni_nombre": "SINCELEJO", "dept_nombre": "SUCRE"},
      {"muni_nombre": "TUNJA", "dept_nombre": "BOYACÁ"},
      {"muni_nombre": "VALLEDUPAR", "dept_nombre": "CESAR"},
      {"muni_nombre": "VILLAVICENCIO", "dept_nombre": "META"},
    ];

    final map = <String, Map<String, String>>{};
    for (var item in rawMapping) {
      final deptRaw = item['dept_nombre']!;
      final capital = item['muni_nombre']!;
      final normalizedKey = _normalize(deptRaw);
      // Solo guardamos la primera ocurrencia (la más representativa)
      if (!map.containsKey(normalizedKey)) {
        map[normalizedKey] = {
          'capital': capital,
          'departamentoOficial': deptRaw,
        };
      }
    }
    return map;
  }();

  /// Normaliza un string: minúsculas, sin acentos, sin puntos.
  static String _normalize(String input) {
    if (input.isEmpty) return input;
    // Reemplazar acentos y ñ
    final normalized = input
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('.', '')
        .trim();
    return normalized;
  }

  /// Dado un departamento (ej: "Boyacá"), devuelve la capital (ej: "TUNJA")
  /// y el nombre oficial del departamento. Si no está en el mapeo, retorna null.
  /// Devuelve un mapa con 'capital' y 'departamentoOficial' o null si no existe.
  static Map<String, String>? _getCapitalInfo(String departamento) {
    final normalized = _normalize(departamento);
    final info = _departmentToCapital[normalized];
    if (info != null) {
      return {'capital': info['capital']!, 'departamentoOficial': info['departamentoOficial']!};
    }
    return null;
  }

  // ----------------------------------------------------------------------
  // Método principal (modificado)
  // ----------------------------------------------------------------------
  static Future<Map<String, dynamic>?> fetchAnalisisTerreno({
    required double lat,
    required double lon,
    required String departamento,
    String? municipio,
  }) async {
    // --- Transformación interna para DANE: usar capital si existe en el mapeo ---
    String departamentoParaQuery = departamento;
    String municipioParaQuery = municipio ?? '';

    final capitalInfo = _getCapitalInfo(departamento);
    if (capitalInfo != null) {
      // Reemplazamos con la capital y el nombre oficial del departamento
      departamentoParaQuery = capitalInfo['departamentoOficial']!;   // ej: "BOYACÁ"
      municipioParaQuery = capitalInfo['capital']!;      // ej: "TUNJA"
      if (kDebugMode) {
        debugPrint('🔁 Mapeo interno para DANE: "$departamento" -> "$departamentoParaQuery", "$municipio" -> "$municipioParaQuery"');
      }
    } else {
      // Si el departamento no está en el mapeo, conservamos los valores originales.
      if (kDebugMode) {
        debugPrint('⚠️ Departamento "$departamento" no está en el mapeo de capitales. Se usa el valor original.');
      }
    }

    // Construcción de la URL con los parámetros transformados
    final uri = Uri.parse('$_baseUrl/analisis-terreno').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'departamento': departamentoParaQuery,
        if (municipioParaQuery.isNotEmpty) 'municipio': municipioParaQuery,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // 📋 LOG TEMPORAL: Imprimir JSON formateado recibido desde /analisis-terreno
        /*if (kDebugMode) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📡 RESPUESTA RECIBIDA: /analisis-terreno');
          debugPrint('═══════════════════════════════════════════════════════');
          
          // Formatear con indentación y imprimir línea por línea para evitar truncado
          final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
          prettyJson.split('\n').forEach((line) => debugPrint(line));
          
          debugPrint('═══════════════════════════════════════════════════════');
        }*/
        
        if (data['success'] == true) {
          return data;
        } else {
          debugPrint('Error API MiSiembra: ${data['error']}');
          return null;
        }
      } else {
        debugPrint('Error HTTP ${response.statusCode}: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error de conexión: $e');
      return null;
    }
  }

  // El método buscarInsumos NO necesita cambios, porque no consulta datos del DANE.
  static Future<Map<String, dynamic>?> buscarInsumos({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse('$_baseUrl/buscar-insumos').replace(
      queryParameters: {'lat': lat.toString(), 'lon': lon.toString()},
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;

        /*if (kDebugMode) {
          debugPrint('═══════════════════════════════════════════════════════');
          debugPrint('📡 RESPUESTA RECIBIDA: /buscar-insumos (proveedores)');
          debugPrint('═══════════════════════════════════════════════════════');
          final prettyJson = const JsonEncoder.withIndent('  ').convert(data);
          prettyJson.split('\n').forEach((line) => debugPrint(line));
          debugPrint('═══════════════════════════════════════════════════════');
        }*/

        return data;
      } else {
        debugPrint('Error buscando insumos: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error de conexión al buscar insumos: $e');
      return null;
    }
  }
}