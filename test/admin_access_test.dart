import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/features/authentication/authentication.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/common/management/operations.dart';
import 'package:untitled/src/features/common/profile/profile.dart';

import 'fixtures/preview_store.dart';

import 'test_support.dart';

class SessionFixture extends PreviewStore {
  bool signedIn = false;
  @override
  bool get live => true;
  @override
  bool get authenticated => signedIn;
  @override
  Future<void> signOut() async {
    signedIn = false;
    changed();
  }
}

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets(
    'administrator profile logout clears session instead of only popping the page',
    (tester) async {
      final store = SessionFixture()
        ..signedIn = true
        ..role = UserRole.admin;
      await tester.pumpWidget(HarvestHubApp(store: store, skipStartup: true));
      await tester.pump(const Duration(seconds: 1));
      final context = tester.element(find.byType(AppShell));
      var backOnly = false;
      openPage(
        context,
        ProfileScreen(
          onExit: () {
            backOnly = true;
          },
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.scrollUntilVisible(
        find.text('Logout'),
        350,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Logout'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();
      expect(store.signedIn, isFalse);
      expect(backOnly, isFalse);
      expect(find.byType(AuthScreen), findsOneWidget);
      expect(find.byType(ProfileScreen), findsNothing);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    },
  );
  testWidgets('live customer keeps the original interface and session store', (
    tester,
  ) async {
    final store = SessionFixture()
      ..signedIn = true
      ..role = UserRole.customer;
    await tester.pumpWidget(HarvestHubApp(store: store, skipStartup: true));
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(
      HarvestScope.of(tester.element(find.byType(HomeScreen))),
      same(store),
    );
    await store.signOut();
    await tester.pumpAndSettle();
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('initialRole cannot bypass a live unauthenticated session', (
    tester,
  ) async {
    final store = SessionFixture();
    await tester.pumpWidget(
      HarvestHubApp(
        store: store,
        initialRole: UserRole.admin,
        skipStartup: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Platform Overview'), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(find.text('Explore Roles Demo'), findsNothing);
  });
  for (final role in [UserRole.customer, UserRole.farmer]) {
    testWidgets('${role.name} cannot directly open administrator screens', (
      tester,
    ) async {
      final store = SessionFixture()
        ..signedIn = true
        ..role = role;
      for (final screen in [
        const UsersScreen(),
        const CategoriesScreen(),
        UserDetailScreen(account: store.accounts.first),
      ]) {
        await tester.pumpWidget(
          HarvestScope(
            store: store,
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Administrator access required.'), findsOneWidget);
      }
    });
  }
  testWidgets('session revocation removes pushed administrator routes', (
    tester,
  ) async {
    final store = SessionFixture()
      ..signedIn = true
      ..role = UserRole.admin;
    await tester.pumpWidget(HarvestHubApp(store: store, skipStartup: true));
    // Live metric placeholders animate continuously while this fixture loads.
    await tester.pump(const Duration(seconds: 1));
    final context = tester.element(find.byType(AppShell));
    openPage(context, const CategoriesScreen());
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Market Categories'), findsOneWidget);
    await store.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Market Categories'), findsNothing);
    expect(find.byType(AuthScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
