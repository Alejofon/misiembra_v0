import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiMiSiembraService {
  // 🔁 REEMPLAZA CON LA URL REAL DE TU API
  static const String _baseUrl = 'https://api-dane-micro.onrender.com';

  /// Obtiene datos consolidados de clima, suelo, insumos y precios DANE
  /// [lat], [lon], [departamento], [municipio] son obligatorios.
  static Future<Map<String, dynamic>?> fetchAnalisisTerreno({
    required double lat,
    required double lon,
    required String departamento,
    String? municipio,
  }) async {
    final uri = Uri.parse('$_baseUrl/analisis-terreno').replace(
      queryParameters: {
        'lat': lat.toString(),
        'lon': lon.toString(),
        'departamento': departamento,
        if (municipio != null && municipio.isNotEmpty) 'municipio': municipio,
      },
    );

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          return data; // incluye las claves: clima, suelo, insumos, precios_mercado
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

  /// Busca proveedores de insumos agrícolas cercanos a las coordenadas dadas.
  static Future<Map<String, dynamic>?> buscarInsumos({
    required double lat,
    required double lon,
  }) async {
    final uri = Uri.parse(
      '$_baseUrl/buscar-insumos',
    ).replace(queryParameters: {'lat': lat.toString(), 'lon': lon.toString()});

    try {
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
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
