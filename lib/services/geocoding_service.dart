import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class GeocodingService {
  /// Obtiene departamento y municipio desde coordenadas usando Nominatim.
  /// Retorna un mapa {"departamento": "...", "municipio": "..."} o null.
  static Future<Map<String, String>?> reverseGeocode(
    double lat,
    double lon, {
    http.Client? client,
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lon&addressdetails=1&accept-language=es',
      );
      final response = await httpClient.get(url, headers: {
        'User-Agent': 'MiSiembraApp/1.0 (alejofon04@gmail.com)',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          String? departamento = address['state'];
          String? municipio = address['city'] ?? address['town'] ?? address['municipality'];

          String normalizedDepartamento = _normalizeDepartmentName(departamento ?? '');
          String normalizedMunicipio = _normalizeMunicipalityName(municipio ?? '');

          return {
            'departamento': normalizedDepartamento,
            'municipio': normalizedMunicipio,
          };
        }
      }
      return null;
    } on SocketException catch (_) {
      return null;
    } on HttpException catch (_) {
      return null;
    } on FormatException catch (_) {
      return null;
    } on http.ClientException catch (_) {
      return null;
    } catch (_) {
      return null;
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  /// Normaliza el nombre del departamento para que coincida con el JSON
  static String _normalizeDepartmentName(String name) {
    if (name.isEmpty) return name;

    // Convertir a título (primera letra mayúscula, resto minúscula)
    String normalized = name.toLowerCase().split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');

    // Casos especiales
    switch (normalized.toUpperCase()) {
      case 'CUNDINAMARCA':
        return 'Cundinamarca';
      case 'BOGOTA':
      case 'BOGOTÁ':
      case 'BOGOTA D.C.':
      case 'BOGOTÁ D.C.':
        return 'Bogotá D.C.';
      case 'NORTE DE SANTANDER':
        return 'Norte de Santander';
      case 'VALLE DEL CAUCA':
        return 'Valle del Cauca';
      default:
        return normalized;
    }
  }

  /// Normaliza el nombre del municipio
  static String _normalizeMunicipalityName(String name) {
    if (name.isEmpty) return name;

    // Para municipios, mantener mayúsculas pero limpiar
    String normalized = name.trim();

    // Casos especiales
    switch (normalized.toUpperCase()) {
      case 'BOGOTA':
      case 'BOGOTÁ':
        return 'Bogotá';
      default:
        return normalized;
    }
  }
}
