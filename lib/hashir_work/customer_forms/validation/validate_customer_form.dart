import 'package:flutter/material.dart';

/// Displays inline errors and brings the first invalid field into view.
bool validateCustomerForm(GlobalKey<FormState> key) {
  FocusManager.instance.primaryFocus?.unfocus();
  final form = key.currentState;
  if (form == null) return false;
  final invalid = form.validateGranularly();
  if (invalid.isEmpty) return true;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    final field = invalid.first;
    if (field.mounted) {
      Scrollable.ensureVisible(
        field.context,
        alignment: .15,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  });
  return false;
}
