import 'package:geocoding/geocoding.dart';

import 'place_resolver.dart';

/// Uses the operating system's free geocoder; no API key or billing account.
Future<String?> resolveNativePlace(double latitude, double longitude) async {
  final places = await Geocoding().placemarkFromCoordinates(
    latitude,
    longitude,
  );
  for (final place in places) {
    final result = formatPlacemark(place);
    if (result != null) return result;
  }
  return null;
}

String? formatPlacemark(Placemark place) {
  final parts = <String>[];
  final seen = <String>{};
  for (final part in [
    place.name,
    place.street,
    place.subLocality,
    place.locality,
    place.subAdministrativeArea,
    place.administrativeArea,
    place.country,
  ]) {
    final text = part?.trim() ?? '';
    if (text.isEmpty || !seen.add(text.toLowerCase())) continue;
    // Some providers return coordinate strings or Plus Codes as the name.
    if (RegExp(r'^[-+\d\s.,°]+$').hasMatch(text) ||
        RegExp(
          r'^[23456789CFGHJMPQRVWX]{2,8}\+[23456789CFGHJMPQRVWX]{2,3}$',
          caseSensitive: false,
        ).hasMatch(text)) {
      continue;
    }
    parts.add(text);
  }
  final address = parts.join(', ');
  return isReadableAddress(address) ? address : null;
}
