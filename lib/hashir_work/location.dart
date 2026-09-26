import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

/// Reads the device position once, returning a readable error on failure.
Future<({double? lat, double? lng, String? error})> currentPosition() async {
  try {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return (lat: null, lng: null, error: 'Turn on location services.');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return (lat: null, lng: null, error: 'Location permission was denied.');
    }
    final p = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );
    return (lat: p.latitude, lng: p.longitude, error: null);
  } catch (e) {
    debugPrint('Location unavailable: $e');
    return (lat: null, lng: null, error: 'Your location is unavailable.');
  }
}
