import 'package:flutter/material.dart';

import '../../components.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';

class PasswordHelpScreen extends StatefulWidget {
  const PasswordHelpScreen({super.key});
  @override
  State<PasswordHelpScreen> createState() => _PasswordHelpScreenState();
}

class _PasswordHelpScreenState extends State<PasswordHelpScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    final result = await HarvestScope.of(context)
        .resetPassword(email.text.trim());
    if (!mounted) return;
    setState(() => busy = false);
    notice(
      context,
      result ??
          'If an account exists for this email, a reset link will be sent.',
      isError: result != null,
    );
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormFrame(
    title: 'Reset password',
    heading: 'A fresh start',
    subtitle: 'Enter your account email to request a password reset.',
    formKey: form,
    busy: busy,
    children: [
      CustomerTextField(controller: email, kind: CustomerFieldKind.email),
      const SizedBox(height: 24),
      FilledButton(onPressed: submit, child: const Text('Request reset link')),
    ],
  );
}
