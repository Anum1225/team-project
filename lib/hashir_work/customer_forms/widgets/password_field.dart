import 'package:flutter/material.dart';

/// Keeps password visibility local and refreshes dependent confirmation errors.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    required this.label,
    required this.validator,
    this.dependsOn,
    this.newPassword = false,
    this.helperText,
    this.onSubmitted,
  });
  final TextEditingController controller;
  final TextEditingController? dependsOn;
  final String label;
  final FormFieldValidator<String> validator;
  final bool newPassword;
  final String? helperText;
  final VoidCallback? onSubmitted;
  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  final fieldKey = GlobalKey<FormFieldState<String>>();
  bool hidden = true;
  @override
  void initState() {
    super.initState();
    widget.dependsOn?.addListener(revalidate);
  }

  @override
  void didUpdateWidget(covariant PasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dependsOn != widget.dependsOn) {
      oldWidget.dependsOn?.removeListener(revalidate);
      widget.dependsOn?.addListener(revalidate);
    }
  }

  void revalidate() {
    if (fieldKey.currentState?.hasInteractedByUser == true ||
        fieldKey.currentState?.hasError == true) {
      fieldKey.currentState?.validate();
    }
  }

  @override
  void dispose() {
    widget.dependsOn?.removeListener(revalidate);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextFormField(
    key: fieldKey,
    controller: widget.controller,
    validator: widget.validator,
    obscureText: hidden,
    autocorrect: false,
    enableSuggestions: false,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    autofillHints: [
      widget.newPassword ? AutofillHints.newPassword : AutofillHints.password,
    ],
    textInputAction: widget.onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    onFieldSubmitted: widget.onSubmitted == null
        ? null
        : (_) => widget.onSubmitted!(),
    decoration: InputDecoration(
      labelText: widget.label,
      errorMaxLines: 3,
      helperText: widget.helperText,
      helperMaxLines: 3,
      suffixIcon: IconButton(
        tooltip: hidden
            ? 'Show ${widget.label.toLowerCase()}'
            : 'Hide ${widget.label.toLowerCase()}',
        onPressed: () => setState(() => hidden = !hidden),
        icon: Icon(
          hidden ? Icons.visibility_outlined : Icons.visibility_off_outlined,
        ),
      ),
    ),
  );
}
