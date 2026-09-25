import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/customer/validation/customer_validators.dart';

void main() {
  test('Names support international names and reject digits and junk', () {
    for (final name in [
      'Ayesha Khan',
      'José O’Neill',
      'محمد علی',
      'Anne-Marie',
    ]) {
      expect(CustomerValidators.name(name), isNull, reason: name);
    }
    for (final name in [
      '',
      ' ',
      '12345',
      '---',
      '<script>',
      'a' * 101,
      'Ali\x00Khan',
    ]) {
      expect(CustomerValidators.name(name), isNotNull, reason: name);
    }
  });

  test('Email checks local part, domain labels and length', () {
    for (final email in [
      'reader+fresh@example.co.uk',
      ' customer@example.com ',
    ]) {
      expect(CustomerValidators.email(email), isNull);
    }
    for (final email in [
      '',
      'abc',
      'a@@b.com',
      '.a@b.com',
      'a.@b.com',
      'a..b@c.com',
      'a@-bad.com',
      'a@b..com',
      'a b@c.com',
      '${'a' * 65}@b.com',
      'a@b.c',
    ]) {
      expect(CustomerValidators.email(email), isNotNull, reason: email);
    }
  });

  test('Phone accepts formatting, not alphabetic junk or too many digits', () {
    expect(CustomerValidators.phone('+92 (300) 123-4567'), isNull);
    expect(
      CustomerValidators.normalizePhone('+92 (300) 123-4567'),
      '+923001234567',
    );
    for (final phone in [
      '',
      'abc12345678',
      '123456',
      '1' * 16,
      '++923001234567',
    ]) {
      expect(CustomerValidators.phone(phone), isNotNull, reason: phone);
    }
  });

  test('New-password rules do not block existing sign-in passwords', () {
    expect(CustomerValidators.currentPassword('abc123'), isNull);
    expect(CustomerValidators.currentPassword('   '), isNotNull);
    expect(CustomerValidators.currentPassword('a' * 4097), isNotNull);
    for (final password in [
      '',
      'abc123',
      'abcdefgh',
      '12345678',
      'ABCDEFG1',
      'a1' * 65,
    ]) {
      expect(CustomerValidators.newPassword(password), isNotNull);
    }
    expect(CustomerValidators.newPassword('Goodpass123'), isNull);
    expect(
      CustomerValidators.newPassword('Goodpass123', current: 'Goodpass123'),
      isNotNull,
    );
    expect(CustomerValidators.confirmPassword('', ''), isNotNull);
    expect(
      CustomerValidators.confirmPassword('Goodpass123 ', 'Goodpass123'),
      isNotNull,
    );
    expect(
      CustomerValidators.confirmPassword('Goodpass123', 'Goodpass123'),
      isNull,
    );
  });

  test(
    'Address and feedback boundaries reject empty, junk and long content',
    () {
      expect(CustomerValidators.address('Main Street, Karachi'), isNull);
      for (final value in ['', 'short', 'a' * 501, ' ' * 20, '.' * 15]) {
        expect(CustomerValidators.address(value), isNotNull);
      }
      expect(
        CustomerValidators.message('Please add more seasonal vegetables.'),
        isNull,
      );
      for (final value in [
        '',
        'short',
        ' ' * 20,
        'a' * 2001,
        'Hello\x00world',
      ]) {
        expect(CustomerValidators.message(value), isNotNull);
      }
    },
  );

  test('Required choices only accept available values', () {
    expect(
      CustomerValidators.selection(null, ['Morning'], 'pickup time'),
      isNotNull,
    );
    expect(
      CustomerValidators.selection('Old slot', ['Morning'], 'pickup time'),
      isNotNull,
    );
    expect(
      CustomerValidators.selection('Morning', ['Morning'], 'pickup time'),
      isNull,
    );
  });
}
