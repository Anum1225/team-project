import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../validation/customer_validators.dart';

enum CustomerFieldKind { name, email, phone, address, message }

/// Common field presentation; validation rules live outside the widgets.
class CustomerTextField extends StatelessWidget {
  const CustomerTextField({
    super.key,
    required this.controller,
    required this.kind,
    this.label,
    this.readOnly = false,
    this.helperText,
    this.textInputAction = TextInputAction.next,
  });
  final bool readOnly;
  final TextEditingController controller;
  final CustomerFieldKind kind;
  final String? label, helperText;
  final TextInputAction textInputAction;

  @override
  Widget build(BuildContext context) {
    final (
      defaultLabel,
      validator,
      keyboard,
      max,
      lines,
      hints,
    ) = switch (kind) {
      CustomerFieldKind.name => (
        'Full name',
        CustomerValidators.name,
        TextInputType.name,
        100,
        1,
        [AutofillHints.name],
      ),
      CustomerFieldKind.email => (
        'Email address',
        CustomerValidators.email,
        TextInputType.emailAddress,
        254,
        1,
        [AutofillHints.email],
      ),
      CustomerFieldKind.phone => (
        'Mobile phone number',
        CustomerValidators.phone,
        TextInputType.phone,
        30,
        1,
        [AutofillHints.telephoneNumber],
      ),
      CustomerFieldKind.address => (
        'Address',
        CustomerValidators.address,
        TextInputType.streetAddress,
        500,
        3,
        [AutofillHints.fullStreetAddress],
      ),
      CustomerFieldKind.message => (
        'Your message',
        CustomerValidators.message,
        TextInputType.multiline,
        2000,
        5,
        <String>[],
      ),
    };
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      decoration: InputDecoration(
        labelText: label ?? defaultLabel,
        helperText: helperText,
        helperMaxLines: 3,
        errorMaxLines: 3,
      ),
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      keyboardType: keyboard,
      autofillHints: hints,
      autocorrect:
          kind != CustomerFieldKind.email && kind != CustomerFieldKind.phone,
      textCapitalization: kind == CustomerFieldKind.name
          ? TextCapitalization.words
          : TextCapitalization.none,
      textInputAction: lines > 1 ? TextInputAction.newline : textInputAction,
      maxLines: lines,
      maxLength: max,
      buildCounter: (
        _, {
        required currentLength,
        required isFocused,
        maxLength,
      }) => null,
      // Preserve pasted content so invalid input is explained, not silently cut.
      maxLengthEnforcement: MaxLengthEnforcement.none,
    );
  }
}
