import 'package:flutter/material.dart';

/// Keeps every field mounted, including fields above a small-screen viewport.
/// A lazy list can otherwise skip their validators when submitting the form.
class CustomerForm extends StatelessWidget {
  const CustomerForm({
    super.key,
    required this.formKey,
    required this.children,
  });
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Form(
    key: formKey,
    child: SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(24),
      child: AutofillGroup(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    ),
  );
}
