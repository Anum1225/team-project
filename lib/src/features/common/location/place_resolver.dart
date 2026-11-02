import 'dart:async';

import 'package:flutter/foundation.dart';

/// Keeps geographic data separate from the address people read and edit.
@immutable
class SelectedLocation {
  const SelectedLocation({
    required this.latitude,
    required this.longitude,
    required this.address,
  });

  final double latitude;
  final double longitude;
  final String address;
}

typedef ReverseGeocode = Future<String?> Function(
  double latitude,
  double longitude,
);

bool isReadableAddress(String value) {
  final address = value.trim();
  return address.length >= 3 &&
      address.length <= 500 &&
      RegExp(r'\p{L}', unicode: true).hasMatch(address) &&
      !RegExp(r'^[-+\d\s.,°]+$').hasMatch(address);
}

/// Debounces map gestures and discards results for a pin that has moved.
/// Addresses are only kept in this picker session, never persisted as a cache.
class PlaceResolver extends ChangeNotifier {
  PlaceResolver(
    this.reverseGeocode, {
    this.debounce = const Duration(milliseconds: 650),
    // A moved pin may wait for one in-flight provider request to finish.
    this.timeout = const Duration(seconds: 22),
  });

  final ReverseGeocode reverseGeocode;
  final Duration debounce;
  final Duration timeout;
  Timer? _timer;
  int _request = 0;
  bool _disposed = false;
  double? _latitude;
  double? _longitude;
  bool resolving = false;
  String? address;
  String? error;

  SelectedLocation? get selection => address == null || _latitude == null
      ? null
      : SelectedLocation(
          latitude: _latitude!,
          longitude: _longitude!,
          address: address!,
        );

  void select(double latitude, double longitude) {
    if (_disposed) return;
    if (!latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      _timer?.cancel();
      ++_request;
      _latitude = null;
      _longitude = null;
      address = null;
      resolving = false;
      error = 'This pin is outside the map. Choose another location.';
      notifyListeners();
      return;
    }
    if (_latitude == latitude &&
        _longitude == longitude &&
        (resolving || address != null)) {
      return;
    }
    _timer?.cancel();
    final request = ++_request;
    _latitude = latitude;
    _longitude = longitude;
    address = null;
    error = null;
    resolving = true;
    notifyListeners();
    _timer = Timer(debounce, () => _resolve(latitude, longitude, request));
  }

  Future<void> _resolve(double latitude, double longitude, int request) async {
    String? result;
    try {
      result = await reverseGeocode(latitude, longitude).timeout(timeout);
    } catch (_) {
      // Provider/platform errors can contain coordinates; show only helpful copy.
    }
    if (_disposed || request != _request) return;
    resolving = false;
    address = result != null && isReadableAddress(result)
        ? result.trim()
        : null;
    error = address == null
        ? 'No place name was found. Move the pin, retry, or enter the address below.'
        : null;
    notifyListeners();
  }

  void useManualAddress(String value) {
    if (_disposed || _latitude == null) return;
    _timer?.cancel();
    ++_request;
    resolving = false;
    address = isReadableAddress(value) ? value.trim() : null;
    error = address == null
        ? 'Enter a place or street name, not just numbers.'
        : null;
    notifyListeners();
  }

  void retry() {
    if (_latitude == null) return;
    final latitude = _latitude!;
    final longitude = _longitude!;
    address = null;
    resolving = false;
    select(latitude, longitude);
  }

  @override
  void dispose() {
    _disposed = true;
    ++_request;
    _timer?.cancel();
    super.dispose();
  }
}
