import 'package:flutter/material.dart';

import 'theme.dart';
export 'customer_forms/screens/auth_screen.dart';
export 'customer_forms/screens/password_help_screen.dart';

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? emailValidator(String? value) =>
    value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Enter a valid email address.'
    : null;

class HarvestField extends StatelessWidget {
  const HarvestField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboard,
    this.validator,
    this.lines = 1,
    this.autofillHints,
    this.helper,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int lines;
  final Iterable<String>? autofillHints;
  final String? helper;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: lines,
    autofillHints: autofillHints,
    validator: validator ?? requiredValidator,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: Harvest.muted)
          : null,
    ),
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
  );
}
