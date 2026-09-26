import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/assistant.dart';
import 'package:untitled/src/auth.dart';
import 'package:untitled/src/components.dart';
import 'package:untitled/src/customer.dart';
import 'package:untitled/src/models.dart';
import 'package:untitled/src/operations.dart';
import 'package:untitled/src/orders.dart';
import 'package:untitled/src/preview_store.dart';
import 'package:untitled/src/profile.dart';
import 'package:untitled/src/theme.dart';

import 'test_support.dart';

const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');
void main() {
  setUpAll(loadHarvestFonts);
  final sizes = [
    const Size(360, 800),
    const Size(393, 873),
    const Size(393, 852),
    const Size(430, 932),
  ];
  for (final size in sizes) {
    for (final scale in size.width == 360 ? [1.0, 1.6] : [1.0]) {
      testWidgets('all detail screens at $size, text $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PreviewStore();
        store.setQuantity('tomato', 2);
        store.toggleSaved('berry');
        final screens = <String, (UserRole, Widget)>{
          'login': (
            UserRole.customer,
            const AuthScreen(role: UserRole.customer),
          ),
          'recovery': (UserRole.customer, const PasswordHelpScreen()),
          'product': (
            UserRole.customer,
            const ProductScreen(productId: 'tomato'),
          ),
          'sold-out': (
            UserRole.customer,
            const ProductScreen(productId: 'berry2'),
          ),
          'farm': (UserRole.customer, const FarmScreen(farmId: 'green')),
          'saved': (UserRole.customer, const WishlistScreen()),
          'basket': (UserRole.customer, const BasketScreen()),
          'checkout': (UserRole.customer, const CheckoutScreen()),
          'confirmation': (
            UserRole.customer,
            ConfirmationScreen(orders: [store.orders.first]),
          ),
          'order': (
            UserRole.customer,
            OrderDetailScreen(order: store.orders.first),
          ),
          'profile-editor': (UserRole.customer, const ProfileEditorScreen()),
          'security': (UserRole.customer, const SecurityScreen()),
          'about': (UserRole.customer, const AboutScreen()),
          'contact': (UserRole.customer, const ContactScreen()),
          'states': (UserRole.customer, const StateGalleryScreen()),
          'assistant': (
            UserRole.customer,
            const Scaffold(body: AssistantScreen()),
          ),
          'inventory-editor': (
            UserRole.farmer,
            ProductEditorScreen(product: store.product('carrot')),
          ),
          'new-product': (UserRole.farmer, const ProductEditorScreen()),
          'farm-editor': (UserRole.farmer, const FarmEditorScreen()),
          'order-management': (
            UserRole.farmer,
            OrderDetailScreen(order: store.orders.first),
          ),
          'categories': (UserRole.admin, const CategoriesScreen()),
          'user-detail': (
            UserRole.admin,
            UserDetailScreen(account: store.accounts[2]),
          ),
        };
        for (final entry in screens.entries) {
          store.role = entry.value.$1;
          final boundary = GlobalKey();
          await tester.pumpWidget(
            HarvestScope(
              store: store,
              child: MaterialApp(
                theme: Harvest.theme,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                    disableAnimations: true,
                  ),
                  child: RepaintBoundary(key: boundary, child: child!),
                ),
                home: KeyedSubtree(
                  key: ValueKey(entry.key),
                  child: entry.value.$2,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${entry.key}, $size, $scale',
          );
          if (capture && size == const Size(393, 852) && scale == 1.0) {
            await tester.runAsync(() async {
              final image =
                  await (boundary.currentContext!.findRenderObject()!
                          as RenderRepaintBoundary)
                      .toImage();
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File('docs/previews/${entry.key}.png');
              await file.parent.create(recursive: true);
              await file.writeAsBytes(bytes!.buffer.asUint8List());
              image.dispose();
            });
          }
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            await tester.drag(
              scrollables.first,
              const Offset(0, -1300),
              warnIfMissed: false,
            );
            await tester.pumpAndSettle();
            expect(
              tester.takeException(),
              isNull,
              reason: '${entry.key} lower content, $size, $scale',
            );
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
        store.dispose();
      });
    }
  }
}
