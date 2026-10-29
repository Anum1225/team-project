import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_support.dart';

import 'package:untitled/main.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/customer/ai_assistant/assistant_robot.dart';

import 'fixtures/preview_store.dart';

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  setUp(() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {
      FlutterError.dumpErrorToConsole(details, forceReport: true);
      previous?.call(details);
    };
    addTearDown(() => FlutterError.onError = previous);
  });
  testWidgets('first run opens role-aware auth directly', (tester) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      HarvestHubApp(skipStartup: true, store: PreviewStore()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Farmer'), findsNothing);
    expect(find.text('Admin'), findsNothing);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.ensureVisible(find.text('Sign Up'));
    await tester.tap(find.text('Sign Up'));
    await tester.pumpAndSettle();
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Farmer'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    await tester.tap(find.text('Farmer'));
    await tester.pumpAndSettle();
    expect(find.text('Create your farmer account'), findsOneWidget);
    expect(find.byTooltip('Choose location on map'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(320, 640),
    const Size(360, 800),
    const Size(393, 873),
    const Size(393, 852),
    const Size(430, 932),
    const Size(800, 360),
    const Size(768, 1024),
    const Size(1280, 800),
  ]) {
    for (final role in UserRole.values) {
      testWidgets('${role.name} tabs at $size', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = size.width == 360
            ? 1.6
            : 1;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        await tester.pumpWidget(
          HarvestHubApp(
            initialRole: role,
            skipStartup: true,
            store: PreviewStore(),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byType(AssistantRobot),
          role == UserRole.customer ? findsOneWidget : findsNothing,
        );
        if (role == UserRole.customer) {
          final bounds = tester.getRect(find.byType(AssistantRobot));
          expect(bounds.center.dx, greaterThan(size.width * .7));
          expect(bounds.width, lessThanOrEqualTo(104));
        }
        final labels = switch (role) {
          UserRole.customer => [
            'Explore',
            'Assistant',
            'Orders',
            'Profile',
            'Home',
          ],
          UserRole.farmer => [
            'Products',
            'Orders',
            'Reports',
            'Profile',
            'Dashboard',
          ],
          UserRole.admin => ['Users', 'Catalog', 'Orders', 'More', 'Dashboard'],
        };
        for (final label in labels) {
          await tester.tap(find.text(label).last);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$role $label $size');
          expect(
            find.byType(AssistantRobot),
            role == UserRole.customer && label == 'Home'
                ? findsOneWidget
                : findsNothing,
            reason: 'Ola must only appear on customer Home',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      });
    }
  }

  testWidgets('customer can filter, save, add to basket and confirm an order', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final store = PreviewStore();
    await tester.pumpWidget(
      HarvestHubApp(
        initialRole: UserRole.customer,
        skipStartup: true,
        store: store,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tomato');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();
    expect(find.text('1 product'), findsOneWidget);
    await tester.tap(find.byTooltip('Save Vine tomatoes'));
    await tester.pumpAndSettle();
    expect(store.saved, contains('tomato'));
    await tester.tap(find.text('Vine tomatoes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(store.basketCount, 1);
    Navigator.of(tester.element(find.text('Add to cart'))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Your basket'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to Checkout · Rs 180'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm order · Rs 180'));
    await tester.pumpAndSettle();
    expect(find.text('Order confirmed'), findsOneWidget);
    expect(store.basket, isEmpty);
    expect(store.product('tomato')!.stock, 23);
    expect(tester.takeException(), isNull);
  });
}
