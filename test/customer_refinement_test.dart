import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/features/customer/ai_assistant/assistant_robot.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';
import 'package:untitled/src/features/customer/customer.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets('choosing another farmer adds that seller offer to the cart', (
    tester,
  ) async {
    final store = PreviewStore();
    final original = store.product('tomato')!;
    final offer = Product(
      id: 'tomato-other-farmer',
      name: original.name,
      category: original.category,
      farmId: 'sun',
      price: original.price + 2000,
      stock: 8,
      image: original.image,
      unit: original.unit,
    );
    store.products.add(offer);
    await tester.pumpWidget(
      HarvestScope(
        store: store,
        child: MaterialApp(
          theme: Harvest.theme,
          home: ProductScreen(product: original),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selector = find.byType(DropdownButtonFormField<String>);
    await tester.ensureVisible(selector);
    await tester.tap(selector);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(store.farm(offer.farmId).name).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();
    expect(store.basket[offer.id], 1);
    expect(store.basket.containsKey(original.id), isFalse);
    expect(store.basketTotal, offer.price);
    expect(tester.takeException(), isNull);
  });
  testWidgets('customer can hide Ola and change theme from the header', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final store = PreviewStore();
    await tester.pumpWidget(
      HarvestHubApp(
        store: store,
        initialRole: UserRole.customer,
        skipStartup: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AssistantRobot), findsOneWidget);
    await tester.tap(find.byTooltip('Hide Ola assistant'));
    await tester.pumpAndSettle();
    expect(find.byType(AssistantRobot), findsNothing);
    expect(
      (await SharedPreferences.getInstance()).getBool(
        'harvesthub_assistant_${store.account.id}',
      ),
      false,
    );
    await tester.tap(find.byTooltip('Switch to dark theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.dark,
    );
    await tester.tap(find.byTooltip('Switch to light theme'));
    await tester.pumpAndSettle();
    expect(
      Theme.of(tester.element(find.byType(AppShell))).brightness,
      Brightness.light,
    );
    expect(tester.takeException(), isNull);
  });
}
