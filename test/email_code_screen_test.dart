import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/authentication/two_step_verification/email_security.dart';

void main() {
  testWidgets(
    'phone code entry keeps leading zeroes and retries without resending',
    (tester) async {
      var sends = 0;
      var verifications = 0;
      final entered = <String>[];
      final serverTime =
          DateTime.now().millisecondsSinceEpoch + 2 * 60 * 60 * 1000;
      await tester.pumpWidget(
        MaterialApp(
          home: EmailCodeScreen(
            onCancel: () async {},
            startCode: (purpose, resend) async {
              sends++;
              expect(purpose, 'login');
              expect(resend, isNull);
              return {
                'challengeId': 'same-challenge',
                'maskedEmail': 'c***@example.test',
                'serverTime': serverTime,
                'expiresAt': serverTime + 30 * 60000,
                'resendAfter': serverTime + 60000,
              };
            },
            verifyCode: (id, code) async {
              expect(id, 'same-challenge');
              entered.add(code);
              if (++verifications == 1) {
                throw StateError('Connection interrupted. Please retry.');
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('valid for 30 minutes'), findsOneWidget);
      expect(
        find.textContaining(RegExp(r'Code expires in (30:00|29:5\d)')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '012345');
      await tester.pump();
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();
      expect(
        find.text('Connection interrupted. Please retry.'),
        findsOneWidget,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '012345',
      );
      await tester.tap(find.text('Verify and continue'));
      await tester.pumpAndSettle();
      expect(entered, ['012345', '012345']);
      expect(sends, 1);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('resend is explicit and updates the active challenge', (
    tester,
  ) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    String? verifiedId;
    await tester.pumpWidget(
      MaterialApp(
        home: EmailCodeScreen(
          onCancel: () async {},
          challenge: {
            'challengeId': 'old',
            'maskedEmail': 'c***@example.test',
            'expiresAt': now + 100000,
            'resendAfter': now - 1000,
          },
          startCode: (purpose, resend) async {
            expect(resend, 'old');
            return {
              'challengeId': 'new',
              'maskedEmail': 'c***@example.test',
              'expiresAt': now + 30 * 60000,
              'resendAfter': now + 60000,
            };
          },
          verifyCode: (id, code) async {
            verifiedId = id;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '123456');
    await tester.tap(find.text('Resend code'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    await tester.enterText(find.byType(TextField), '654321');
    await tester.pump();
    await tester.tap(find.text('Verify and continue'));
    await tester.pumpAndSettle();
    expect(verifiedId, 'new');
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
