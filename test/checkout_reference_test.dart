import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/orders/orders.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  for (final width in [360.0, 393.0]) {
    testWidgets('checkout contact snapshot and progress at width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = PreviewStore();
      final originalName = store.account.name;
      final originalPhone = store.account.phone;
      store.setQuantity('tomato', 1);
      final boundary = GlobalKey();
      Widget page(Widget screen) => HarvestScope(
        store: store,
        child: MaterialApp(
          theme: Harvest.theme,
          home: RepaintBoundary(key: boundary, child: screen),
        ),
      );
      await tester.pumpWidget(page(const CheckoutScreen()));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const Key('checkout-name')),
        'Ayesha Khan',
      );
      await tester.enterText(find.byKey(const Key('checkout-phone')), '123');
      await tester.tap(find.text('Confirm order · Rs 180'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Enter a valid mobile'), findsOneWidget);
      expect(store.basketCount, 1);
      await tester.enterText(
        find.byKey(const Key('checkout-phone')),
        '03001234567',
      );
      await tester.ensureVisible(find.byKey(const Key('checkout-address')));
      await tester.enterText(
        find.byKey(const Key('checkout-address')),
        '12 New Street, Karachi',
      );
      await tester.ensureVisible(find.byKey(const Key('checkout-note')));
      await tester.enterText(
        find.byKey(const Key('checkout-note')),
        'Please pack separately',
      );
      tester.testTextInput.hide();
      await tester.pumpAndSettle();
      if (width == 393) {
        await tester.scrollUntilVisible(
          find.text('Payment Method'),
          150,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
        await capture(tester, boundary, 'checkout-review');
      }
      await tester.tap(find.text('Confirm order · Rs 180'));
      await tester.pumpAndSettle();
      expect(find.byType(ConfirmationScreen), findsOneWidget);
      final order = store.orders.last;
      expect(order.contactName, 'Ayesha Khan');
      expect(order.phone, '+923001234567');
      expect(order.address, '12 New Street, Karachi');
      expect(order.note, 'Please pack separately');
      expect(order.paymentMethod, 'cashOnDelivery');
      expect(store.account.name, originalName);
      expect(store.account.phone, originalPhone);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(page(OrderDetailScreen(order: order)));
      await tester.pumpAndSettle();
      expect(find.text('Book a pickup'), findsOneWidget);
      expect(find.text('Progress Timeline'), findsOneWidget);
      if (width == 393) await capture(tester, boundary, 'order-progress');
      for (final status in [
        OrderStatus.confirmed,
        OrderStatus.ready,
        OrderStatus.completed,
      ]) {
        order.status = status;
        store.changed();
        await tester.pumpAndSettle();
        final statusRow = find
            .ancestor(
              of: find.text('Current Status'),
              matching: find.byType(Row),
            )
            .first;
        expect(
          find.descendant(of: statusRow, matching: find.text(status.label)),
          findsOneWidget,
        );
      }
      await tester.scrollUntilVisible(
        find.text('Delivery & Customer Info'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.text('Ayesha Khan'), findsOneWidget);
      expect(find.text('+923001234567'), findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.text('Please pack separately'), findsOneWidget);
      if (width == 393) await capture(tester, boundary, 'order-contact');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      store.dispose();
    });
  }
}

Future<void> capture(WidgetTester tester, GlobalKey key, String name) async {
  if (!const bool.fromEnvironment('CAPTURE_ORDER_PREVIEWS')) return;
  final boundary =
      key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await File('.local-backups/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}
