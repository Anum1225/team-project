import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/features/common/notifications/notifications.dart';
import 'package:untitled/src/features/common/notifications/live_inbox.dart';
import 'package:untitled/src/features/common/profile/preferences.dart';
import 'package:untitled/src/features/common/markets/market_directory.dart';
import 'package:untitled/src/features/common/reports/reporting.dart';
import 'package:untitled/src/features/common/data/public_content.dart';
import 'package:untitled/src/features/authentication/two_step_verification/email_security.dart';
import 'package:untitled/src/features/customer/ai_assistant/assistant.dart';
import 'package:untitled/src/features/authentication/authentication.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/common/management/operations.dart';
import 'package:untitled/src/features/common/orders/orders.dart';

import 'fixtures/preview_store.dart';

import 'package:untitled/src/features/common/profile/profile.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

import 'test_support.dart';

const capture = bool.fromEnvironment('CAPTURE_PREVIEWS');

class LayoutContentRepository extends PublicContentRepository {
  @override
  Future<PublicContent> load() async => PublicContent.fromData(null);
}

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  final sizes = [
    const Size(320, 640),
    const Size(360, 800),
    const Size(393, 873),
    const Size(393, 852),
    const Size(430, 932),
    const Size(800, 360),
    const Size(768, 1024),
    const Size(1280, 800),
  ];
  for (final size in sizes) {
    for (final scale in size.width == 360 ? [1.0, 1.6] : [1.0]) {
      testWidgets('all detail screens at $size, text $scale', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final store = PreviewStore();
        store.report = {
          'totalOrders': 12,
          'orderValue': 250000,
          'completedValue': 175000,
          'trend': [0, 10000, 20000, 15000, 45000, 60000, 25000],
          'statuses': {for (final status in OrderStatus.values) status.name: 2},
          'farmers': [
            {
              'name': 'Greenwood Family Farm',
              'completed': 7,
              'value': 175000,
              'orders': 12,
            },
          ],
          'markets': [
            {
              'name': 'Local farmers market',
              'orders': 12,
              'completed': 7,
              'value': 175000,
            },
          ],
        };
        store.setQuantity('tomato', 2);
        store.toggleSaved('berry');
        if (capture) {
          final p = store.product('tomato')!;
          store.products.add(
            Product(
              id: 'manual-other-tomato',
              name: p.name,
              category: p.category,
              farmId: 'sun',
              price: p.price + 2000,
              stock: 9,
              image: p.image,
              unit: p.unit,
            ),
          );
        }
        final screens = <String, (UserRole, Widget)>{
          'login': (
            UserRole.customer,
            const AuthScreen(role: UserRole.customer),
          ),
          'recovery': (UserRole.customer, const PasswordHelpScreen()),
          'farmer-login': (
            UserRole.farmer,
            const AuthScreen(role: UserRole.farmer),
          ),
          'admin-login': (
            UserRole.admin,
            const AuthScreen(role: UserRole.admin),
          ),
          'email-code': (
            UserRole.customer,
            EmailCodeScreen(
              onCancel: () async {},
              challenge: {
                'challengeId': 'layout-test',
                'maskedEmail': 'm***@example.test',
                'expiresAt': DateTime.now().millisecondsSinceEpoch + 1800000,
                'resendAfter': DateTime.now().millisecondsSinceEpoch + 60000,
              },
            ),
          ),
          'notifications': (
            UserRole.admin,
            const NotificationsScreen(
              inbox: NotificationMessage(
                'You’re all caught up. New updates will appear here.',
              ),
            ),
          ),
          'preferences': (UserRole.customer, const PreferencesScreen()),
          'markets': (UserRole.customer, const MarketDirectory()),
          'admin-reports': (UserRole.admin, const AdminReportsScreen()),
          'admin-settings': (
            UserRole.admin,
            AdminSettingsScreen(onUsers: () {}, onCategories: () {}),
          ),
          'reviews': (UserRole.admin, const ReviewsScreen()),
          'about-editor': (
            UserRole.admin,
            PublicContentEditor(repository: LayoutContentRepository()),
          ),
          'market-editor': (UserRole.admin, const MarketEditor()),
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
            // Native image decoding runs outside the widget test's fake clock.
            // Wait for visible photos before exporting the screen.
            final pictures = find.byType(Image).evaluate().toList();
            await tester.runAsync(() async {
              for (final element in pictures) {
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
              final bytes = await image.toByteData(
                format: ui.ImageByteFormat.png,
              );
              final file = File(
                '${const String.fromEnvironment('CAPTURE_DIR', defaultValue: 'docs/previews')}/${entry.key}.png',
              );
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
