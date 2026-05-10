import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Obtiene la posición actual del dispositivo.
  /// Retorna (lat, lon) o null si falla.
  static Future<Position?> getCurrentPosition() async {
    try {
      // 1. Verificar que el servicio de ubicación esté habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('El GPS está desactivado. Actívalo e inténtalo de nuevo.');
      }

      // 2. Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Permiso de ubicación denegado. Ve a ajustes de la app.');
        }
      }
      if (permission == LocationPermission.deniedForever) {
        // Abrir configuración de ubicación
        await Geolocator.openLocationSettings();
        throw Exception('Permiso de ubicación denegado permanentemente. Se abrió la configuración, concede el permiso y vuelve a intentar.');
      }

      // 3. Obtener posición
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      // Re-lanzar con mensaje más descriptivo
      if (e is LocationServiceDisabledException) {
        throw Exception('El GPS está desactivado. Actívalo e inténtalo de nuevo.');
      } else if (e is PermissionDeniedException) {
        throw Exception('Permiso de ubicación denegado. Ve a ajustes.');
      } else {
        // Para timeout y otros errores
        throw Exception('Error al obtener ubicación: ${e.toString()}');
      }
    }
  }
}