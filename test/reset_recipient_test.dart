import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/authentication/authentication.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

class ResetStore extends PreviewStore {
  String? recipient;
  final completion = Completer<String?>();
  @override
  Future<String?> resetPassword(String email) {
    recipient = email;
    return completion.future;
  }
}

void main() {
  setUpAll(loadHarvestFonts);
  testWidgets(
    'reset and confirmation retain the submitted email after editing',
    (tester) async {
      final store = ResetStore();
      await tester.pumpWidget(
        HarvestScope(
          store: store,
          child: MaterialApp(
            theme: Harvest.theme,
            home: const PasswordHelpScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'first@example.com');
      await tester.ensureVisible(find.text('Request reset link'));
      await tester.tap(find.text('Request reset link'));
      await tester.pump();
      expect(store.recipient, 'first@example.com');
      await tester.enterText(find.byType(TextFormField), 'second@example.com');
      store.completion.complete(null);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('If an account exists for first@example.com,'),
        findsOneWidget,
      );
      expect(
        find.textContaining('If an account exists for second@example.com,'),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );

  for (final scale in [1.0, 1.6]) {
    testWidgets(
      'product card Add to cart fits narrow grid at text $scale and adds item',
      (tester) async {
        final store = PreviewStore();
        await tester.pumpWidget(
          HarvestScope(
            store: store,
            child: MaterialApp(
              theme: Harvest.theme,
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: Center(
                    child: SizedBox(
                      width: 326,
                      child: ProductGrid(
                        products: [store.product('tomato')!],
                        onOpen: (_) {},
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.add), findsNothing);
        await tester.tap(find.text('Add to cart'));
        await tester.pump();
        expect(store.basket['tomato'], 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
}
