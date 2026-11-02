import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'fixtures/preview_store.dart';

import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets(
    'settings theme switch changes palette and preserves the signed-in session',
    (tester) async {
      final store = PreviewStore();
      await tester.pumpWidget(
        HarvestHubApp(
          store: store,
          initialRole: UserRole.admin,
          skipStartup: true,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      expect(find.text('Admin Profile'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      expect(find.text('Dark appearance'), findsOneWidget);
      expect(
        tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
        isTrue,
      );
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AppShell), findsOneWidget);
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.dark,
      );
      await tester.tap(find.text('More').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.light,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        HarvestHubApp(
          store: PreviewStore(),
          initialRole: UserRole.admin,
          skipStartup: true,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(AppShell))).brightness,
        Brightness.light,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
