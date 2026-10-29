import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geocoding/geocoding.dart';
import 'package:untitled/src/features/common/location/native_geocoder.dart';
import 'package:untitled/src/features/common/location/place_resolver.dart';

void main() {
  test(
    'invalid geographic values cannot trigger a lookup or retain an old pin',
    () {
      var calls = 0;
      final resolver = PlaceResolver((_, _) async {
        ++calls;
        return 'Karachi';
      });
      addTearDown(resolver.dispose);
      for (final point in [
        [double.nan, 67.0],
        [24.0, double.infinity],
        [91.0, 67.0],
        [-91.0, 67.0],
        [24.0, 181.0],
        [24.0, -181.0],
      ]) {
        resolver.select(24, 67);
        resolver.useManualAddress('Karachi');
        resolver.select(point[0], point[1]);
        expect(resolver.selection, isNull);
        expect(resolver.resolving, isFalse);
        expect(resolver.error, contains('outside the map'));
      }
      expect(calls, 0);
    },
  );

  test('native address omits coordinate labels and duplicate components', () {
    expect(
      formatPlacemark(
        const Placemark(
          name: '24.8607, 67.0011',
          street: 'Shahrah-e-Faisal',
          subLocality: 'Malir',
          locality: 'Karachi',
          subAdministrativeArea: 'karachi',
          administrativeArea: 'Sindh',
          country: 'Pakistan',
        ),
      ),
      'Shahrah-e-Faisal, Malir, Karachi, Sindh, Pakistan',
    );
    expect(formatPlacemark(const Placemark(name: '24.8607, 67.0011')), isNull);
    expect(formatPlacemark(const Placemark(name: '7J4V+9Q')), isNull);
    expect(isReadableAddress('کراچی، ملیر'), isTrue);
  });

  testWidgets('map gestures are debounced and coordinates are preserved', (
    tester,
  ) async {
    final calls = <double>[];
    final resolver = PlaceResolver((latitude, longitude) async {
      calls.add(latitude);
      return 'Malir, Karachi, Pakistan';
    });
    addTearDown(resolver.dispose);
    resolver.select(24.8, 67.1);
    await tester.pump(const Duration(milliseconds: 300));
    resolver.select(24.9, 67.2);
    await tester.pump(const Duration(milliseconds: 650));
    expect(calls, [24.9]);
    expect(resolver.selection!.latitude, 24.9);
    expect(resolver.selection!.longitude, 67.2);
    expect(resolver.selection!.address, 'Malir, Karachi, Pakistan');
  });

  testWidgets('late responses cannot overwrite a newer pin', (tester) async {
    final old = Completer<String?>();
    final latest = Completer<String?>();
    final resolver = PlaceResolver(
      (latitude, _) => latitude == 1 ? old.future : latest.future,
      debounce: Duration.zero,
    );
    addTearDown(resolver.dispose);
    resolver.select(1, 2);
    await tester.pump(const Duration(milliseconds: 1));
    resolver.select(3, 4);
    await tester.pump(const Duration(milliseconds: 1));
    latest.complete('Latest place');
    await tester.pump(const Duration(milliseconds: 1));
    old.complete('Old place');
    await tester.pump(const Duration(milliseconds: 1));
    expect(resolver.selection!.latitude, 3);
    expect(resolver.selection!.address, 'Latest place');
  });

  testWidgets('provider failures never turn coordinates into an address', (
    tester,
  ) async {
    final resolver = PlaceResolver(
      (_, _) async => throw StateError('provider failed'),
      debounce: Duration.zero,
    );
    addTearDown(resolver.dispose);
    resolver.select(24.9, 67.2);
    await tester.pump(const Duration(milliseconds: 1));
    expect(resolver.selection, isNull);
    expect(resolver.error, contains('enter the address'));
    resolver.useManualAddress('1234567890');
    expect(resolver.selection, isNull);
    resolver.useManualAddress('Malir, Karachi');
    expect(resolver.selection!.address, 'Malir, Karachi');
    expect(resolver.selection!.longitude, 67.2);
  });

  testWidgets('manual address wins over an in-flight provider response', (
    tester,
  ) async {
    final pending = Completer<String?>();
    final resolver = PlaceResolver(
      (_, _) => pending.future,
      debounce: Duration.zero,
    );
    addTearDown(resolver.dispose);
    resolver.select(1, 2);
    await tester.pump(const Duration(milliseconds: 1));
    resolver.useManualAddress('My street, Karachi');
    pending.complete('Provider address');
    await tester.pump(const Duration(milliseconds: 1));
    expect(resolver.selection!.address, 'My street, Karachi');
  });

  testWidgets('lookup times out and allows a fresh retry', (tester) async {
    final pending = Completer<String?>();
    var attempts = 0;
    final resolver = PlaceResolver(
      (_, _) => ++attempts == 1 ? pending.future : Future.value('Karachi'),
      debounce: Duration.zero,
      timeout: const Duration(seconds: 1),
    );
    addTearDown(resolver.dispose);
    resolver.select(1, 2);
    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(resolver.resolving, isFalse);
    expect(resolver.selection, isNull);
    resolver.retry();
    await tester.pump(const Duration(milliseconds: 1));
    expect(resolver.selection!.address, 'Karachi');
    pending.complete('Late address');
    await tester.pump(const Duration(milliseconds: 1));
    expect(resolver.selection!.address, 'Karachi');
  });
}
