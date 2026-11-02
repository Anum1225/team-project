import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:untitled/src/app.dart';
import 'package:untitled/src/features/customer/ai_assistant/assistant_robot.dart';
import 'package:untitled/src/features/common/data/assistant_preferences.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/common/profile/preferences.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/harvest_sprout.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

void main() {
  setUpAll(loadHarvestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test(
    'assistant preference persists, isolates accounts, and wins pending load',
    () async {
      final preferences = AssistantPreferences();
      expect(preferences.enabledFor('customer'), isNull);
      final loading = preferences.load('customer');
      expect(await preferences.setEnabled('customer', false), isTrue);
      await loading;
      expect(preferences.enabledFor('customer'), isFalse);
      final restarted = AssistantPreferences();
      await restarted.load('customer');
      await restarted.load('another');
      expect(restarted.enabledFor('customer'), isFalse);
      expect(restarted.enabledFor('another'), isTrue);
      preferences.dispose();
      restarted.dispose();
    },
  );

  testWidgets('dismissed Ola stays hidden on return and settings restores it', (
    tester,
  ) async {
    final store = PreviewStore();
    await tester.pumpWidget(
      HarvestHubApp(
        store: store,
        initialRole: UserRole.customer,
        skipStartup: true,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Hide Ola assistant'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Explore').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home').last);
    await tester.pump();
    expect(find.byType(AssistantRobot), findsNothing);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(AssistantRobot), findsNothing);
    await tester.pumpAndSettle();
    final context = tester.element(find.byType(AppShell));
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const PreferencesScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Show Ola assistant'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(PreferencesScreen))).pop();
    await tester.pumpAndSettle();
    expect(find.byType(AssistantRobot), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'thumbnail renders uploaded image, asset filename, and invalid URI safely',
    (tester) async {
      final data = File('assets/images/tomatoes.jpg').readAsBytesSync();
      for (final source in [
        'data:image/jpeg;base64,${base64Encode(data)}',
        'tomatoes.jpg',
        'data:image/png;base64,%%%',
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(child: Photo(source, width: 68, height: 68)),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getSize(find.byType(Photo)), const Size(68, 68));
        if (!source.endsWith('%%%')) {
          await tester.runAsync(
            () => precacheImage(
              tester.widget<Image>(find.byType(Image)).image,
              tester.element(find.byType(Photo)),
            ),
          );
          await tester.pumpAndSettle();
          final rendered = tester.widget<RawImage>(find.byType(RawImage));
          expect(rendered.image, isNotNull);
        } else {
          expect(find.byIcon(Icons.spa_outlined), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('admin cards show loading until data arrives', (tester) async {
    final store = PreviewStore()..reportLoading = true;
    await tester.pumpWidget(
      HarvestHubApp(
        store: store,
        initialRole: UserRole.admin,
        skipStartup: true,
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Updating…'), findsWidgets);
    store.reportLoading = false;
    store.changed();
    await tester.pumpAndSettle();
    expect(find.text('Updating…'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture balanced splash emblem', (tester) async {
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xffeaf0e5),
          body: Center(
            child: RepaintBoundary(
              key: boundary,
              child: Container(
                width: 260,
                height: 260,
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff084b32),
                  border: Border.all(color: const Color(0xffefc96f), width: 2),
                ),
                child: CustomPaint(
                  painter: HarvestSproutPainter(
                    progress: 1,
                    color: const Color(0xffbce5bd),
                    accentColor: const Color(0xffefc96f),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.runAsync(() async {
      final image =
          await (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('docs/previews/splash-emblem.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
}
