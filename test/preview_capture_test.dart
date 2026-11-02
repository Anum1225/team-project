import 'fixtures/preview_store.dart';

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/main.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets('capture role screens for visual review', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final role in UserRole.values) {
      if (const bool.fromEnvironment('CAPTURE_CUSTOMER_ONLY') &&
          role != UserRole.customer) {
        continue;
      }
      final boundary = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundary,
          child: HarvestHubApp(
            initialRole: role,
            skipStartup: true,
            store: PreviewStore(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final labels = switch (role) {
        UserRole.customer => [
          'Home',
          'Explore',
          'Assistant',
          'Orders',
          'Profile',
        ],
        UserRole.farmer => [
          'Dashboard',
          'Products',
          'Orders',
          'Reports',
          'Profile',
        ],
        UserRole.admin => ['Dashboard', 'Users', 'Catalog', 'Orders', 'More'],
      };
      for (final label in labels) {
        await tester.tap(find.text(label).last);
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          for (final element in find.byType(Image).evaluate().toList()) {
            await precacheImage(
              (element.widget as Image).image,
              element,
              onError: (error, stack) {},
            );
          }
        });
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image =
              await (boundary.currentContext!.findRenderObject()!
                      as RenderRepaintBoundary)
                  .toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final file = File(
            '${const String.fromEnvironment('CAPTURE_DIR', defaultValue: 'docs/previews')}/${role.name}-${label.toLowerCase()}.png',
          );
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();
    }
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
}
