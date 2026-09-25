import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/customer/app.dart';
import 'package:untitled/customer/data/pickup_slots.dart';
import 'package:untitled/customer/data/sample_catalog.dart';
import 'package:untitled/customer/models/customer_session.dart';
import 'package:untitled/customer/screens/about_screen.dart';
import 'package:untitled/customer/screens/assistant_screen.dart';
import 'package:untitled/customer/screens/cart_screen.dart';
import 'package:untitled/customer/screens/catalog_screen.dart';
import 'package:untitled/customer/screens/checkout_screen.dart';
import 'package:untitled/customer/screens/contact_screen.dart';
import 'package:untitled/customer/screens/customer_shell.dart';
import 'package:untitled/customer/screens/edit_profile_screen.dart';
import 'package:untitled/customer/screens/farmer_screen.dart';
import 'package:untitled/customer/screens/farmers_screen.dart';
import 'package:untitled/customer/screens/notifications_screen.dart';
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
import 'package:untitled/customer/screens/wishlist_screen.dart';
import 'package:untitled/customer/state/customer_store.dart';
import 'package:untitled/customer/theme/customer_theme.dart';

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
  test('Cart enforces stock and checkout snapshots order lines', () {
    final store = CustomerStore(CustomerSession.customer);
    expect(store.add(products[6]), false);
    expect(store.add(products.first, 25), false);
    expect(store.add(products.first, 2), true);
    expect(store.add(products[1]), true);
    expect(store.subtotal, 680);
    expect(store.checkout('Karachi', {'green': pickupSlots().first}), isNull);
    expect(store.cartCount, 3);
    final order = store.checkout('Karachi', {
      'green': pickupSlots().first,
      'sun': pickupSlots().last,
    })!;
    expect(order.total, 680);
    expect(store.cart, isEmpty);
    expect(store.stock(products.first), 22);
    store.add(products.first);
    expect(order.lines.first.quantity, 2);
    store.updatePickup(order, 'green', null);
    expect(order.pickups.containsKey('green'), false);
    expect(order.pickups.containsKey('sun'), true);
    store.updatePickup(order, 'green', pickupSlots().last);
    expect(order.pickups['green'], pickupSlots().last);
  });

  testWidgets('Welcome opens customer experience without other roles', (
    tester,
  ) async {
    await tester.pumpWidget(const HarvestHubApp());
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Explore customer demo'));
    await tester.tap(find.text('Explore customer demo'));
    await tester.pumpAndSettle();
    expect(find.text('Fresh finds, just for you.'), findsOneWidget);
    expect(find.text('Admin'), findsNothing);
    expect(find.text('Farmer dashboard'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Search filters dynamically and wishlist updates', (
    tester,
  ) async {
    final store = CustomerStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        home: CustomerShell(store: store),
      ),
    );
    await tester.tap(find.text('Explore'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'tomato');
    await tester.pumpAndSettle();
    expect(find.text('Vine tomatoes'), findsOneWidget);
    expect(find.text('Creamy avocados'), findsNothing);
    await tester.tap(find.byTooltip('Save Vine tomatoes'));
    await tester.pumpAndSettle();
    expect(store.wishlist, contains('tomato'));
    await tester.tap(find.text('Wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('Vine tomatoes'), findsOneWidget);
    await tester.tap(find.byTooltip('Remove Vine tomatoes from wishlist'));
    await tester.pumpAndSettle();
    expect(find.text('Keep the good stuff close'), findsOneWidget);
  });

  testWidgets('Checkout validates pickup before showing order confirmation', (
    tester,
  ) async {
    final store = CustomerStore(CustomerSession.customer)
      ..add(products.first, 2);
    await tester.pumpWidget(
      MaterialApp(
        theme: customerTheme(),
        home: CheckoutScreen(store: store),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Confirm simulated order'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Confirm simulated order'));
    await tester.pumpAndSettle();
    expect(store.orders, isEmpty);
    await tester.scrollUntilVisible(
      find.byType(DropdownButtonFormField<String>),
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(pickupSlots().first).last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Confirm simulated order'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Confirm simulated order'));
    await tester.pumpAndSettle();
    expect(find.text('Good things are growing.'), findsOneWidget);
    expect(store.orders.single.total, 360);
    expect(store.cart, isEmpty);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 1280.0]) {
    testWidgets('Customer screens fit ${width.toInt()}px viewport', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 850);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = CustomerStore(CustomerSession.customer)
        ..add(products.first);
      final order = store.checkout('12 Garden Street, Karachi', {
        'green': pickupSlots().first,
      })!;
      store.add(products[1]);
      store.toggleWish('basil');
      store.toggleFollow('green');
      final screens = <Widget>[
        WelcomeScreen(store: store),
        SignInScreen(store: store),
        RegisterScreen(store: store),
        ResetPasswordScreen(store: store),
        CustomerShell(store: store),
        Scaffold(body: CatalogScreen(store: store)),
        ProductScreen(product: products.first, store: store),
        ProductScreen(product: products[6], store: store),
        Scaffold(
          body: WishlistScreen(store: store, onBrowse: () {}),
        ),
        CartScreen(store: store),
        CheckoutScreen(store: store),
        SuccessScreen(order: order, store: store),
        Scaffold(
          body: OrdersScreen(store: store, onBrowse: () {}),
        ),
        OrderScreen(store: store, order: order),
        PickupScreen(store: store, order: order, farmer: farmers.first),
        FarmersScreen(store: store),
        FarmerScreen(farmer: farmers.first, store: store),
        Scaffold(body: ProfileScreen(store: store)),
        EditProfileScreen(store: store),
        PasswordScreen(store: store),
        NotificationsScreen(store: store),
        AssistantScreen(store: store),
        const AboutScreen(),
        ContactScreen(store: store),
      ];
      for (final screen in screens) {
        await tester.pumpWidget(
          MaterialApp(theme: customerTheme(), home: screen),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: '${screen.runtimeType} at $width',
        );
        final scrollables = find.byType(Scrollable);
        if (scrollables.evaluate().isNotEmpty && screen is! AssistantScreen) {
          await tester.drag(scrollables.first, const Offset(0, -650));
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} scrolled at $width',
          );
        }
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });
  }

  testWidgets('Capture home preview for visual review', (tester) async {
    tester.view.physicalSize = const Size(1280, 1250);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final key = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: customerTheme(),
          home: CustomerShell(store: CustomerStore()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build/customer-preview').createSync(recursive: true);
      File('build/customer-preview/home-desktop.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      File('build/customer-preview/home-mobile.png')
          .writeAsBytesSync(data!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
  });
}
