import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/features/common/notifications/notifications.dart';
import 'package:untitled/src/features/common/notifications/live_inbox.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  for (final role in UserRole.values) {
    testWidgets(
      '${role.name} notification message keeps margins and wraps at large text',
      (tester) async {
        tester.view.physicalSize = const Size(320, 640);
        tester.view.devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = 2;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        const message = 'You’re all caught up. New updates will appear here.';
        await tester.pumpWidget(
          HarvestScope(
            store: PreviewStore()..role = role,
            child: MaterialApp(
              theme: Harvest.theme,
              home: const NotificationsScreen(
                inbox: NotificationMessage(message),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final rect = tester.getRect(find.text(message));
        expect(rect.left, greaterThanOrEqualTo(24));
        expect(rect.right, lessThanOrEqualTo(296));
        expect(
          tester.widget<Text>(find.text(message)).textAlign,
          TextAlign.center,
        );
        await tester.drag(find.byType(NestedScrollView), const Offset(0, -200));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
