import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/customer/data/pickup_slots.dart';
import 'package:untitled/customer/data/sample_catalog.dart';
import 'package:untitled/customer/models/customer_profile.dart';
import 'package:untitled/customer/models/customer_session.dart';
import 'package:untitled/customer/screens/cart_screen.dart';
import 'package:untitled/customer/screens/checkout_screen.dart';
import 'package:untitled/customer/screens/contact_screen.dart';
import 'package:untitled/customer/screens/edit_profile_screen.dart';
import 'package:untitled/customer/screens/order_screen.dart';
import 'package:untitled/customer/screens/orders_screen.dart';
import 'package:untitled/customer/screens/password_screen.dart';
import 'package:untitled/customer/screens/pickup_screen.dart';
import 'package:untitled/customer/screens/product_screen.dart';
import 'package:untitled/customer/screens/profile_screen.dart';
import 'package:untitled/customer/screens/register_screen.dart';
import 'package:untitled/customer/screens/reset_password_screen.dart';
import 'package:untitled/customer/screens/sign_in_screen.dart';
import 'package:untitled/customer/screens/success_screen.dart';
import 'package:untitled/customer/screens/welcome_screen.dart';
import 'package:untitled/customer/state/customer_store.dart';
import 'package:untitled/customer/theme/customer_theme.dart';
import 'package:untitled/customer/widgets/product_card.dart';
import 'package:untitled/customer/widgets/quantity_picker.dart';
import 'package:untitled/customer/widgets/sign_in_required.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    await (FontLoader('Roboto')
          ..addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'))
          ..addFont(rootBundle.load('assets/fonts/roboto-bold.ttf')))
        .load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });

  test('Demo allows favorites but blocks shopping and account mutations', () {
    final store = CustomerStore();
    expect(store.isDemo, isTrue);
    store.toggleWish('tomato');
    store.toggleFollow('green');
    expect(store.wishlist, contains('tomato'));
    expect(store.followed, contains('green'));
    expect(store.add(products.first), isFalse);
    store.quantity(products.first, 2);
    expect(store.cart, isEmpty);
    store.updateProfile(CustomerProfile(name: 'Changed Name'));
    expect(store.profile.name, 'Alex Morgan');
    // Even a stale/preloaded cart cannot bypass checkout's state-level guard.
    store.cart['tomato'] = 2;
    expect(
      store.checkout('12 Garden Street, Karachi', {
        'green': pickupSlots().first,
      }),
      isNull,
    );
    expect(store.orders, isEmpty);
    expect(store.purchased, isEmpty);
    store.toggleWish('tomato');
    store.toggleFollow('green');
    expect(store.wishlist, isEmpty);
    expect(store.followed, isEmpty);
  });

  test(
    'Entering demo revokes shopping access and keeps browsing favorites',
    () {
      final store = CustomerStore(CustomerSession.customer);
      store.toggleWish('tomato');
      store.toggleFollow('green');
      store.add(products.first);
      final order = store.checkout('12 Garden Street, Karachi', {
        'green': pickupSlots().first,
      })!;
      store.add(products[1]);
      final originalSlot = order.pickups['green'];
      store.enterDemo();
      expect(store.canShop, isFalse);
      expect(store.cart, isEmpty);
      expect(store.orders, isEmpty);
      expect(store.wishlist, contains('tomato'));
      expect(store.followed, contains('green'));
      store.updatePickup(order, 'green', null);
      expect(order.pickups['green'], originalSlot);
      expect(store.add(products.first), isFalse);
      store.reset();
      expect(store.isDemo, isTrue);
      expect(store.wishlist, isEmpty);
    },
  );

  testWidgets(
    'Demo cards and product details expose favorites, not cart controls',
    (tester) async {
      final store = CustomerStore();
      await tester.pumpWidget(
        MaterialApp(
          theme: customerTheme(),
          home: Scaffold(
            body: ListenableBuilder(
              listenable: store,
              builder: (_, _) => Center(
                child: SizedBox(
                  width: 220,
                  height: 294,
                  child: ProductCard(product: products.first, store: store),
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byTooltip('Add Vine tomatoes to cart'), findsNothing);
      await tester.tap(find.byTooltip('Save Vine tomatoes'));
      await tester.pumpAndSettle();
      expect(store.wishlist, contains('tomato'));
      await tester.tap(find.text('Vine tomatoes'));
      await tester.pumpAndSettle();
      expect(find.byType(ProductScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Sign in to shop'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.byType(QuantityPicker), findsNothing);
      await tester.tap(find.text('Sign in to shop'));
      await tester.pumpAndSettle();
      expect(find.byType(SignInScreen), findsOneWidget);
      expect(store.cart, isEmpty);
      expect(store.canShop, isFalse);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Direct shopping and account routes stay locked in demo', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final customer = CustomerStore(CustomerSession.customer)
      ..add(products.first);
    final order = customer.checkout('12 Garden Street, Karachi', {
      'green': pickupSlots().first,
    })!;
    final demo = CustomerStore();
    final routes = <Widget>[
      CartScreen(store: demo),
      CheckoutScreen(store: demo),
      Scaffold(
        body: OrdersScreen(store: demo, onBrowse: () {}),
      ),
      OrderScreen(store: demo, order: order),
      SuccessScreen(store: demo, order: order),
      PickupScreen(store: demo, order: order, farmer: farmers.first),
      Scaffold(body: ProfileScreen(store: demo)),
      EditProfileScreen(store: demo),
      PasswordScreen(store: demo),
      ContactScreen(store: demo),
    ];
    for (final route in routes) {
      await tester.pumpWidget(MaterialApp(theme: customerTheme(), home: route));
      await tester.pumpAndSettle();
      expect(
        find.byType(SignInRequired),
        findsOneWidget,
        reason: '${route.runtimeType}',
      );
      expect(find.text('Confirm simulated order'), findsNothing);
      expect(find.text('Save pickup time'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('Every demo entry revokes access and preserves favorites', (
    tester,
  ) async {
    for (var i = 0; i < 4; i++) {
      final store = CustomerStore(CustomerSession.customer)
        ..toggleWish('tomato')
        ..add(products.first);
      final screen = switch (i) {
        0 => WelcomeScreen(store: store),
        1 => SignInScreen(store: store),
        2 => RegisterScreen(store: store),
        _ => ResetPasswordScreen(store: store),
      };
      await tester.pumpWidget(
        MaterialApp(theme: customerTheme(), home: screen),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Explore customer demo'));
      await tester.tap(find.text('Explore customer demo'));
      await tester.pumpAndSettle();
      expect(store.isDemo, isTrue);
      expect(store.cart, isEmpty);
      expect(store.wishlist, contains('tomato'));
      expect(find.text('Fresh finds, just for you.'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });
}
