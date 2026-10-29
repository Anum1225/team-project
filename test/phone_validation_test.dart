import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/shared/forms/phone_countries.dart';
import 'package:untitled/src/features/common/shared/forms/phone_field.dart';
import 'package:untitled/src/features/common/shared/forms/phone_validation.dart';

void main() {
  test(
    'Pakistan legacy and international mobile inputs normalize to E.164',
    () {
      for (final value in [
        '0312 3456789',
        '3123456789',
        '+92 312-3456789',
        '0092 3123456789',
        '۰۳۱۲۳۴۵۶۷۸۹',
      ]) {
        expect(normalizePhoneNumber(value), '+923123456789', reason: value);
      }
    },
  );
  test('selected country applies its national numbering pattern', () {
    expect(
      normalizePhoneNumber('07400 123456', country: IsoCode.GB),
      '+447400123456',
    );
    expect(
      normalizePhoneNumber('050 1234567', country: IsoCode.AE),
      '+971501234567',
    );
    expect(
      normalizePhoneNumber('(202) 555-0123', country: IsoCode.US),
      '+12025550123',
    );
    expect(phoneNumberError('07400 123456', country: IsoCode.PK), isNotNull);
    expect(normalizePhoneNumber('+44 7400 123456'), '+447400123456');
  });
  test('malformed, incomplete and invalid national patterns are rejected', () {
    for (final value in [
      '',
      '1234567890',
      '0000000000',
      '0312',
      '0312345678900',
      '+9991234567890',
      '0312hello3456789',
      '03123456789 ext 4',
      '++923123456789',
    ]) {
      expect(phoneNumberError(value), isNotNull, reason: value);
      expect(
        () => normalizePhoneNumber(value),
        throwsFormatException,
        reason: value,
      );
    }
    expect(phoneNumberError('1234567890', country: IsoCode.US), isNotNull);
  });
  test('support phone permits valid fixed lines and optional empty input', () {
    expect(phoneNumberError('02134567890'), isNotNull);
    expect(
      normalizePhoneNumber('02134567890', mobileOnly: false),
      '+922134567890',
    );
    expect(normalizePhoneNumber('', required: false), '');
    expect(phoneCountryNames.keys.toSet(), IsoCode.values.toSet());
    for (final country in IsoCode.values) {
      expect(phoneDialCode(country), matches(RegExp(r'^\d{1,3}$')));
    }
  });
  testWidgets(
    'country picker changes validation and form saves international number',
    (tester) async {
      final controller = TextEditingController();
      final form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Form(
              key: form,
              child: PhoneField(controller: controller),
            ),
          ),
        ),
      );
      expect(find.textContaining('Pakistan (+92)'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '1234567890');
      expect(form.currentState!.validate(), isFalse);
      await tester.tap(find.textContaining('Pakistan (+92)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField).last, 'United Kingdom');
      await tester.pump();
      await tester.tap(find.widgetWithText(ListTile, 'United Kingdom'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), '07400123456');
      expect(form.currentState!.validate(), isTrue);
      form.currentState!.save();
      expect(controller.text, '+447400123456');
      await tester.enterText(find.byType(TextFormField), '+923123456789');
      await tester.pump();
      expect(find.textContaining('Pakistan (+92)'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
}
