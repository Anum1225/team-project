part of '../authentication.dart';

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? nameValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Full name is required.';
  }
  if (value.trim().length < 3) {
    return 'Full name must be at least 3 characters.';
  }
  if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
    return 'Name can only contain letters, spaces, and hyphens.';
  }
  return null;
}

String? phoneValidator(String? value) => phoneNumberError(value);

String? addressValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Address is required.';
  }
  if (value.trim().length < 6) {
    return 'Please enter a complete address (at least 6 characters).';
  }
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter a valid email address.';
  }
  final clean = value.trim();
  final regex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );
  if (!regex.hasMatch(clean)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? passwordValidator(String? value, {bool isRegistration = false}) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (isRegistration) {
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include both uppercase and lowercase letters.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one number (0–9).';
    }
  }
  return null;
}

int calculatePasswordStrength(String password) {
  if (password.isEmpty) return 0;
  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
  return score;
}
