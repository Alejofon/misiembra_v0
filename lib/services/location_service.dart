import 'dart:async';

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Obtiene la posición actual del dispositivo.
  /// Retorna (lat, lon) o null si falla.
  static Future<Position?> getCurrentPosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        throw Exception('El GPS está desactivado. Actívalo e inténtalo de nuevo.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Permiso de ubicación denegado. Ve a ajustes de la app.');
      }

      try {
        return await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 15),
        );
      } on TimeoutException catch (_) {
        final lastKnown = await Geolocator.getLastKnownPosition();
        if (lastKnown != null) {
          return lastKnown;
        }
        throw Exception('No se pudo obtener una ubicación precisa. Mueve el dispositivo al exterior y vuelve a intentarlo.');
      }
    } catch (e) {
      if (e is LocationServiceDisabledException) {
        throw Exception('El GPS está desactivado. Actívalo e inténtalo de nuevo.');
      } else if (e is PermissionDeniedException) {
        throw Exception('Permiso de ubicación denegado. Ve a ajustes.');
      } else {
        throw Exception('Error al obtener ubicación: ${e.toString()}');
      }
    }
  }
}