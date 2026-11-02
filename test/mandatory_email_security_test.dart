import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/authentication/two_step_verification/email_security.dart';

void main() {
  for (final role in ['admin', 'customer', 'farmer']) {
    test('$role honors disabled 2FA and validates proof when enabled', () {
      for (final flag in [null, false, true]) {
        final profile = <String, dynamic>{
          'role': role,
          'email': 'person@example.test',
          'email2faEnabled': ?flag,
        };
        final proof = <String, dynamic>{
          'firebase': {'sign_in_provider': 'custom'},
          'hh_email_2fa': true,
          'hh_security_version': 0,
          'hh_verified_email': profile['email'],
        };
        expect(validEmailSecurityClaims({}, profile), flag == false);
        expect(
          validEmailSecurityClaims({
            'email_verified': true,
            'firebase': {'sign_in_provider': 'password'},
          }, profile),
          flag == false,
        );
        expect(validEmailSecurityClaims(proof, profile), isTrue);
        expect(
          validEmailSecurityClaims({
            ...proof,
            'hh_security_version': 1,
          }, profile),
          flag == false,
        );
        expect(
          validEmailSecurityClaims({
            ...proof,
            'hh_verified_email': 'other@example.test',
          }, profile),
          flag == false,
        );
      }
    });
  }
  for (final enabled in [true, false]) {
    testWidgets(
      'settings ${enabled ? 'disables' : 'enables'} only after successful verification',
      (tester) async {
        final profiles = StreamController<Map<String, dynamic>>();
        addTearDown(profiles.close);
        var sends = 0;
        var attempts = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: EmailSecurityPanel(
                profiles: profiles.stream,
                startCode: (purpose, password) async {
                  sends++;
                  expect(purpose, enabled ? 'disable' : 'enroll');
                  expect(password, 'TestOnly123');
                  final now = DateTime.now().millisecondsSinceEpoch;
                  return {
                    'challengeId': 'test-challenge',
                    'maskedEmail': 'p***@example.test',
                    'expiresAt': now + 1800000,
                    'resendAfter': now + 60000,
                  };
                },
                verifyCode: (id, code) async {
                  expect(id, 'test-challenge');
                  if (++attempts == 1) {
                    throw StateError('Incorrect code. Try again.');
                  }
                  expect(code, '012345');
                  profiles.add({'email2faEnabled': !enabled});
                },
              ),
            ),
          ),
        );
        profiles.add({'email2faEnabled': enabled});
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.byType(Switch)).value, enabled);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(sends, 0);
        expect(tester.widget<Switch>(find.byType(Switch)).value, enabled);
        await tester.tap(find.byType(Switch));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), 'TestOnly123');
        await tester.tap(find.text('Send code'));
        // The settings panel has an indeterminate progress indicator underneath this route.
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(sends, 1);
        await tester.enterText(find.byType(TextField), '000000');
        await tester.pump();
        await tester.tap(find.text('Verify and continue'));
        await tester.pumpAndSettle();
        expect(find.text('Incorrect code. Try again.'), findsOneWidget);
        await tester.enterText(find.byType(TextField), '012345');
        await tester.pump();
        await tester.tap(find.text('Verify and continue'));
        await tester.pumpAndSettle();
        expect(tester.widget<Switch>(find.byType(Switch)).value, !enabled);
        expect(
          find.text(
            enabled
                ? 'Two-step verification disabled.'
                : 'Two-step verification enabled.',
          ),
          findsOneWidget,
        );
        await tester.pumpWidget(const SizedBox());
      },
    );
  }
  testWidgets('loading and profile failures never expose an active toggle', (
    tester,
  ) async {
    final profiles = StreamController<Map<String, dynamic>>();
    addTearDown(profiles.close);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: EmailSecurityPanel(profiles: profiles.stream)),
      ),
    );
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    profiles.addError(StateError('Offline'));
    await tester.pumpAndSettle();
    expect(tester.widget<Switch>(find.byType(Switch)).onChanged, isNull);
    expect(
      find.textContaining('Could not load security settings'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
  });
}
