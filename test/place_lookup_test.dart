import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:untitled/src/features/common/location/place_lookup.dart';

void main() {
  test(
    'native failure falls back to a readable remote address and caches it',
    () async {
      var requests = 0;
      final lookup = PlaceLookup(
        native: (_, _) async => throw StateError('Geocoder unavailable'),
        client: MockClient((request) async {
          requests++;
          expect(request.url.host, 'nominatim.openstreetmap.org');
          expect(request.url.queryParameters['lat'], '24.86');
          return http.Response(
            '{"display_name":"Saddar, Karachi, Pakistan"}',
            200,
          );
        }),
      );
      expect(await lookup.call(24.86, 67.01), 'Saddar, Karachi, Pakistan');
      expect(await lookup.call(24.86, 67.01), 'Saddar, Karachi, Pakistan');
      expect(requests, 1);
      lookup.close();
    },
  );

  test(
    'pin changes discard queued obsolete lookups before calling a provider',
    () async {
      final first = Completer<String?>();
      final calls = <double>[];
      final lookup = PlaceLookup(
        native: (lat, _) {
          calls.add(lat);
          return lat == 1
              ? first.future
              : Future.value('Latest selected place');
        },
        client: MockClient(
          (_) async => throw StateError('Unexpected fallback'),
        ),
      );
      final a = lookup.call(1, 1);
      await Future<void>.delayed(Duration.zero);
      final b = lookup.call(2, 2);
      final c = lookup.call(3, 3);
      first.complete('Previous selected place');
      expect(await a, isNull);
      expect(await b, isNull);
      expect(await c, 'Latest selected place');
      expect(calls, [1, 3]);
      lookup.close();
    },
  );
}
