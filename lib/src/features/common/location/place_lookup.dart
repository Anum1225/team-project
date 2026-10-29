import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'native_geocoder.dart';
import 'place_resolver.dart';

/// Serial requests avoid Android geocoder's concurrent-call failure. The
/// fallback is limited to one request per second and cached for this session.
class PlaceLookup {
  PlaceLookup({ReverseGeocode? native, http.Client? client})
    : native = native ?? resolveNativePlace,
      client = client ?? http.Client();
  final ReverseGeocode native;
  final http.Client client;
  final _cache = <String, String>{};
  Future<void> _queue = Future.value();
  DateTime _lastRemote = DateTime.fromMillisecondsSinceEpoch(0);
  bool _closed = false;
  int _latestRequest = 0;

  Future<String?> call(double lat, double lng) {
    final result = Completer<String?>();
    final request = ++_latestRequest;
    _queue = _queue.then((_) async {
      if (_closed || request != _latestRequest) {
        result.complete(null);
        return;
      }
      final key = '${lat.toStringAsFixed(5)},${lng.toStringAsFixed(5)}';
      if (_cache.containsKey(key)) {
        result.complete(_cache[key]);
        return;
      }
      String? address;
      try {
        if (!kIsWeb &&
            (defaultTargetPlatform == TargetPlatform.android ||
                defaultTargetPlatform == TargetPlatform.iOS)) {
          address = await native(lat, lng).timeout(const Duration(seconds: 4));
        }
      } catch (_) {
        /* Fall back when native geocoding is unavailable. */
      }
      if (_closed || request != _latestRequest) {
        result.complete(null);
        return;
      }
      try {
        if (address == null || !isReadableAddress(address)) {
          final wait =
              1100 - DateTime.now().difference(_lastRemote).inMilliseconds;
          if (wait > 0) {
            await Future<void>.delayed(Duration(milliseconds: wait));
          }
          if (_closed || request != _latestRequest) {
            result.complete(null);
            return;
          }
          _lastRemote = DateTime.now();
          final response = await client
              .get(
                Uri.https('nominatim.openstreetmap.org', '/reverse', {
                  'lat': '$lat',
                  'lon': '$lng',
                  'format': 'jsonv2',
                  'addressdetails': '1',
                  'zoom': '18',
                  'accept-language': 'en',
                }),
                headers: {
                  if (!kIsWeb)
                    'User-Agent': 'HarvestHub/1.0 (com.example.untitled)',
                },
              )
              .timeout(const Duration(seconds: 6));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body) as Map<String, dynamic>;
            address = data['display_name'] as String?;
          }
        }
      } catch (_) {
        /* The editable address field remains available. */
      }
      if (address != null && isReadableAddress(address)) {
        if (_cache.length >= 40) _cache.remove(_cache.keys.first);
        _cache[key] = address.trim();
        result.complete(address.trim());
      } else {
        result.complete(null);
      }
    });
    return result.future;
  }

  void close() {
    _closed = true;
    client.close();
  }
}
