import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/components.dart';
import 'package:untitled/src/models.dart';
import 'package:untitled/src/operations.dart';
import 'package:untitled/src/preview_store.dart';

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
    expect(find.byType(WelcomeScreen), findsOneWidget);
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
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppShell));
    openPage(context, const CategoriesScreen());
    await tester.pumpAndSettle();
    expect(find.text('Market Categories'), findsOneWidget);
    await store.signOut();
    await tester.pumpAndSettle();
    expect(find.text('Market Categories'), findsNothing);
    expect(find.byType(WelcomeScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
