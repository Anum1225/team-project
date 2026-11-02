/// Customer input rules adapted from the bookstore project's Validate class.
/// These validate input structure, not account credentials or mailbox ownership.
abstract final class CustomerValidators {
  static String? text(String? input, String label, int min, int max) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return '$label is required.';
    if (value.length < min || value.length > max) {
      return '$label must contain $min–$max characters.';
    }
    if (RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]').hasMatch(value)) {
      return '$label contains unsupported characters.';
    }
    if (!RegExp(r'[\p{L}\p{N}]', unicode: true).hasMatch(value)) {
      return 'Enter a meaningful ${label.toLowerCase()}.';
    }
    return null;
  }

  static String? name(String? input) {
    final error = text(input, 'Name', 2, 100);
    if (error != null) return error;
    return RegExp(
          r"^[\p{L}\p{M} .’'-]+$",
          unicode: true,
        ).hasMatch(input!.trim())
        ? null
        : 'Use letters, spaces, apostrophes or hyphens for the name.';
  }

  static String? email(String? input) {
    final value = input?.trim() ?? '';
    if (value.isEmpty) return 'Email address is required.';
    final parts = value.split('@');
    if (value.length > 254 ||
        parts.length != 2 ||
        parts[0].length > 64 ||
        parts[0].startsWith('.') ||
        parts[0].endsWith('.') ||
        parts[0].contains('..') ||
        !RegExp(r"^[A-Za-z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(parts[0])) {
      return 'Enter a valid email address.';
    }
    final labels = parts[1].split('.');
    if (labels.length < 2 ||
        labels.any(
          (label) =>
              !RegExp(r'^[A-Za-z0-9](?:[A-Za-z0-9-]{0,61}[A-Za-z0-9])?$')
                  .hasMatch(label),
        ) ||
        !RegExp(r'^[A-Za-z]{2,63}$').hasMatch(labels.last)) {
      return 'Enter a valid email address.';
    }
    return null;
  }

  static String normalizePhone(String value) =>
      value.trim().replaceAll(RegExp(r'[ ()-]'), '');

  static String? phone(String? input) {
    if (input == null || input.trim().isEmpty) {
      return 'Phone number is required.';
    }
    if (input.length > 30 ||
        !RegExp(r'^\+?[0-9 ()-]+$').hasMatch(input.trim()) ||
        !RegExp(r'^\+?[0-9]{7,15}$').hasMatch(normalizePhone(input))) {
      return 'Enter 7–15 digits with an optional country code.';
    }
    return null;
  }

  static String? address(String? input) => text(input, 'Address', 12, 500);
  static String? message(String? input) => text(input, 'Message', 10, 2000);

  // Do not apply new-password strength rules to existing login credentials.
  static String? currentPassword(String? input) {
    final value = input ?? '';
    return value.trim().isEmpty || value.length > 4096
        ? 'Enter your password.'
        : null;
  }

  static String? newPassword(String? input, {String? current}) {
    final value = input ?? '';
    if (value.isEmpty) return 'New password is required.';
    if (value.length < 8 ||
        value.length > 128 ||
        !RegExp(r'[a-z]').hasMatch(value) ||
        !RegExp(r'[0-9]').hasMatch(value)) {
      return 'Use 8–128 characters including a lowercase letter and a number.';
    }
    if (current != null && value == current) {
      return 'Choose a different password.';
    }
    return null;
  }

  static String? confirmPassword(String? input, String password) {
    if (input == null || input.isEmpty) return 'Please confirm your password.';
    return input == password ? null : 'Passwords do not match.';
  }

  static String? selection(
    String? value,
    Iterable<String> allowed,
    String label,
  ) => value == null || !allowed.contains(value)
      ? 'Choose a valid $label.'
      : null;
}
