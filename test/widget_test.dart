import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'test_support.dart';

import 'package:untitled/main.dart';
import 'package:untitled/src/models.dart';
import 'package:untitled/src/preview_store.dart';

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets('welcome offers distinct roles and explicit design preview', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(393, 873);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      HarvestHubApp(skipStartup: true, store: PreviewStore()),
    );
    await tester.pumpAndSettle();
    expect(find.text('Shop fresh'), findsOneWidget);
    await tester.tap(find.text('Shop fresh'));
    await tester.pumpAndSettle();
    expect(find.text('Welcome\nback.'), findsOneWidget);
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [
    const Size(360, 800),
    const Size(393, 873),
    const Size(393, 852),
    const Size(430, 932),
  ]) {
    for (final role in UserRole.values) {
      testWidgets('${role.name} tabs at $size', (tester) async {
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
        }
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
    expect(find.text('1 fresh finds'), findsOneWidget);
    await tester.tap(find.byTooltip('Save Vine tomatoes'));
    await tester.pumpAndSettle();
    expect(store.saved, contains('tomato'));
    await tester.tap(find.text('Vine tomatoes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to basket'));
    await tester.pumpAndSettle();
    expect(store.basketCount, 1);
    Navigator.of(tester.element(find.text('Add to basket'))).pop();
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
