import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/main.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

class PendingRegistrationStore extends PreviewStore {
  bool submitted = false;

  @override
  Future<String?> register(
    String email,
    String password,
    String name,
    String phone,
    String address,
    UserRole selected,
  ) async {
    submitted = true;
    return null;
  }
}

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('successful signup opens login mode with approval notice', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PendingRegistrationStore();
    await tester.pumpWidget(HarvestHubApp(skipStartup: true, store: store));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Full name'),
      'New Customer',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Mobile phone'),
      '03001234567',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Street address'),
      '12 Market Street',
    );
    await tester.ensureVisible(find.text('Continue →'));
    await tester.tap(find.text('Continue →'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Email address'),
      'newcustomer@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Password'),
      'StrongPass123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Confirm Password'),
      'StrongPass123',
    );
    await tester.ensureVisible(find.text('Create Account →'));
    await tester.tap(find.text('Create Account →'));
    await tester.pumpAndSettle();

    expect(store.submitted, isTrue);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.textContaining('Wait for admin approval'), findsOneWidget);
    expect(find.text('Create Account →'), findsNothing);
  });
}
