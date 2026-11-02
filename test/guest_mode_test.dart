import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/features/common/data/guest_store.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/authentication/authentication.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/markets/market_directory.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

Map<String, dynamic> catalog() => {
  'products': [
    {
      'id': 'tomato',
      'name': 'Vine tomatoes',
      'category': 'Vegetables',
      'farmId': 'green',
      'price': 18000,
      'stock': 24,
      'image': 'tomatoes',
      'unit': 'kg',
      'description': 'Fresh tomatoes',
    },
  ],
  'farms': [
    {
      'id': 'green',
      'name': 'Greenwood Farm',
      'location': 'Karachi',
      'market': 'Local market',
      'image': 'farmer',
      'pickupSlots': ['Morning'],
    },
  ],
  'categories': [
    {'name': 'Vegetables'},
  ],
  'markets': [
    {'id': 'market', 'name': 'Local market', 'location': 'Karachi'},
  ],
  'cursors': {
    'products': null,
    'farms': null,
    'categories': null,
    'markets': null,
  },
};

class SessionFixture extends PreviewStore {
  bool signedIn = false;
  @override
  bool get live => true;
  @override
  bool get authenticated => signedIn;
}

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('guest supports catalog pagination and local actions but cannot create orders', () async {
    var calls = 0;
    final store = GuestStore(
      onSignIn: () {},
      loadPage: (cursors) async {
        calls++;
        if (calls == 1) {
          return {
            ...catalog(),
            'products': [],
            'cursors': {
              'products': 'first',
              'farms': null,
              'categories': null,
              'markets': null,
            },
          };
        }
        expect(cursors['products'], 'first');
        return {...catalog(), 'farms': [], 'categories': [], 'markets': []};
      },
    );
    await store.refresh();
    expect(store.authenticated, isFalse);
    expect(calls, 2);
    expect(store.products.single.name, 'Vine tomatoes');
    expect(
      marketListings(store.publicMarkets, store.farms).single['id'],
      'market',
    );
    expect(
      store.setQuantity('tomato', 2),
      'Sign in to add products to your cart.',
    );
    expect(store.basket, isEmpty);
    store.toggleSaved('tomato');
    await store.toggleFollowed('green');
    expect(store.saved, contains('tomato'));
    expect(store.followed, contains('green'));
    expect(() => store.checkout('A street'), throwsStateError);
    expect(store.orders, isEmpty);
    expect(store.products.single.stock, 24);
    store.dispose();
  });
  testWidgets(
    'catalog card opens details and wishlist requires sign-in without changing guest basket',
    (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var signIns = 0;
      final guest = GuestStore(
        onSignIn: () => signIns++,
        loadPage: (_) async => catalog(),
      );
      await guest.refresh();
      guest.toggleSaved('tomato');
      var detailsOpened = 0;
      for (final screen in [
        Scaffold(
          body: ProductGrid(products: guest.products, onOpen: (_) => detailsOpened++),
        ),
        const WishlistScreen(),
      ]) {
        await tester.pumpWidget(
          HarvestScope(
            store: guest,
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Add to cart').first);
        await tester.pumpAndSettle();
        if (screen is Scaffold) {
          expect(detailsOpened, 1);
          expect(guest.basket, isEmpty);
          continue;
        }
        expect(find.text('Sign in to add to cart'), findsOneWidget);
        expect(guest.basket, isEmpty);
        await tester.tap(find.text('Sign in / Create account'));
        await tester.pumpAndSettle();
        expect(guest.basket, isEmpty);
      }
      expect(signIns, 1);
      await tester.pumpWidget(const SizedBox.shrink());
      guest.dispose();
    },
  );
  testWidgets(
    'guest cannot fill a basket and signed-in customer can add products',
    (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final account = SessionFixture();
      await tester.pumpWidget(
        HarvestHubApp(
          store: account,
          skipStartup: true,
          guestCatalogLoader: (_) async => catalog(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore demo mode'));
      await tester.tap(find.text('Explore demo mode'));
      await tester.pumpAndSettle();
      final guest =
          HarvestScope.of(tester.element(find.byType(AppShell))) as GuestStore;
      expect(guest.setQuantity('tomato', 2), isNotNull);
      expect(guest.basket, isEmpty);
      guest.requestSignIn();
      await tester.pumpAndSettle();
      account.signedIn = true;
      account.loading = true;
      account.changed();
      await tester.pump();
      expect(account.basket, isEmpty);
      account.loading = false;
      account.changed();
      await tester.pumpAndSettle();
      expect(account.basket, isEmpty);
      expect(account.setQuantity('tomato', 2), isNull);
      expect(account.basket['tomato'], 2);
      await tester.pumpWidget(const SizedBox.shrink());
      account.dispose();
    },
  );
  testWidgets(
    'demo opens live browsing and product detail add-to-cart requests sign-in',
    (tester) async {
      tester.view.physicalSize = const Size(393, 873);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        HarvestHubApp(
          store: PreviewStore(),
          skipStartup: true,
          guestCatalogLoader: (_) async => catalog(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore demo mode'));
      await tester.tap(find.text('Explore demo mode'));
      await tester.pumpAndSettle();
      expect(find.text('Demo · Browse the live catalog'), findsOneWidget);
      final guest =
          HarvestScope.of(tester.element(find.byType(AppShell))) as GuestStore;
      await tester.tap(find.text('Explore').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Vine tomatoes').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      expect(guest.basketCount, 0);
      expect(find.text('Sign in to add to cart'), findsOneWidget);
      expect(find.byType(CheckoutScreen), findsNothing);
      expect(guest.orders, isEmpty);
      await tester.tap(find.text('Keep browsing'));
      await tester.pumpAndSettle();
      expect(guest.basketCount, 0);
      await tester.tap(find.text('Add to cart'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign in / Create account'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
      await tester.ensureVisible(find.text('Explore demo mode'));
      await tester.tap(find.text('Explore demo mode'));
      await tester.pumpAndSettle();
      expect(guest.basketCount, 0);
      for (final tab in ['Assistant', 'Orders', 'Profile', 'Home']) {
        await tester.tap(find.text(tab).last);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
