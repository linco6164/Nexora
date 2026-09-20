import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';

class LocationService {
  static Future<Position?> getCurrentLocation() async {
    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        debugPrint(
          'LOCATION: serviciul de locație este dezactivat.',
        );
        return null;
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        debugPrint(
          'LOCATION: permisiunea a fost refuzată.',
        );
        return null;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        debugPrint(
          'LOCATION: permisiunea a fost refuzată permanent.',
        );
        return null;
      }

      final position =
          await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      debugPrint(
        'LOCATION: ${position.latitude}, ${position.longitude}',
      );

      return position;
    } catch (e) {
      debugPrint(
        'LOCATION ERROR: $e',
      );
      return null;
    }
  }
}