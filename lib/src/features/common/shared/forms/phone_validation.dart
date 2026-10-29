import 'package:phone_numbers_parser/phone_numbers_parser.dart';

export 'package:phone_numbers_parser/phone_numbers_parser.dart' show IsoCode;

// Format validation uses libphonenumber metadata. It does not prove ownership.
String _westernDigits(String value) => String.fromCharCodes(
  value.runes.map((r) {
    if (r >= 0x660 && r <= 0x669) return r - 0x660 + 48;
    if (r >= 0x6f0 && r <= 0x6f9) return r - 0x6f0 + 48;
    return r;
  }),
);

PhoneNumber? parsedPhoneNumber(String value, {IsoCode country = IsoCode.PK}) {
  final clean = _westernDigits(value.trim());
  // Reject letters/extensions rather than silently extracting their digits.
  if (clean.isEmpty ||
      clean.length > 40 ||
      !RegExp(r'^\+?[0-9\s().-]+$').hasMatch(clean)) {
    return null;
  }
  try {
    return PhoneNumber.parse(clean, callerCountry: country);
  } catch (_) {
    return null;
  }
}

String? phoneNumberError(
  String? value, {
  IsoCode country = IsoCode.PK,
  bool mobileOnly = true,
  bool required = true,
}) {
  if (value == null || value.trim().isEmpty) {
    return required ? 'Enter your phone number.' : null;
  }
  final number = parsedPhoneNumber(value, country: country);
  if (number == null ||
      !number.isValid(type: mobileOnly ? PhoneNumberType.mobile : null)) {
    return mobileOnly
        ? 'Enter a valid mobile number for the selected country.'
        : 'Enter a valid phone number for the selected country.';
  }
  return null;
}

/// Returns E.164, accepting local legacy Pakistan and international formats.
String normalizePhoneNumber(
  String value, {
  IsoCode country = IsoCode.PK,
  bool mobileOnly = true,
  bool required = true,
}) {
  final error = phoneNumberError(
    value,
    country: country,
    mobileOnly: mobileOnly,
    required: required,
  );
  if (error != null) throw FormatException(error);
  if (value.trim().isEmpty) return '';
  return parsedPhoneNumber(value, country: country)!.international;
}

String phoneDialCode(IsoCode country) =>
    PhoneNumber(isoCode: country, nsn: '').countryCode;
