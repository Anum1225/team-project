import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/features/authentication/authentication.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/profile/profile.dart';
import 'package:untitled/src/features/common/management/operations.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets('phone forms remain scrollable with the keyboard open', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    final store = PreviewStore()..setQuantity('tomato', 1);
    for (final entry in <String, (UserRole, Widget)>{
      'login': (UserRole.customer, const AuthScreen(role: UserRole.customer)),
      'reset': (UserRole.customer, const PasswordHelpScreen()),
      'checkout': (UserRole.customer, const CheckoutScreen()),
      'profile': (UserRole.customer, const ProfileEditorScreen()),
      'product': (UserRole.farmer, const ProductEditorScreen()),
      'farm': (UserRole.farmer, const FarmEditorScreen()),
      'contact': (UserRole.customer, const ContactScreen()),
    }.entries) {
      store.role = entry.value.$1;
      await tester.pumpWidget(
        HarvestScope(
          store: store,
          child: MaterialApp(
            theme: Harvest.theme,
            home: KeyedSubtree(key: ValueKey(entry.key), child: entry.value.$2),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: entry.key);
      final fields = find.byType(TextField);
      if (fields.evaluate().isNotEmpty) {
        await tester.ensureVisible(fields.last);
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${entry.key} scrolled field',
        );
      }
      await tester.pumpWidget(const SizedBox());
    }
    store.dispose();
  });
}
