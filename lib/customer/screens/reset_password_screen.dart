import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../utils/demo_navigation.dart';
import '../utils/navigation.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    try {
      await widget.store.resetPassword(email.text.trim());
      if (mounted) {
        toast(
          context,
          'If an account exists for this email, a reset link will be sent.',
        );
      }
    } catch (e) {
      if (mounted) toast(context, FirebaseCustomerService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormFrame(
    busy: busy,
    title: 'Reset password',
    heading: 'A fresh start',
    subtitle: 'Enter your account email to request a password reset.',
    formKey: form,
    children: [
      CustomerTextField(
        controller: email,
        kind: CustomerFieldKind.email,
        textInputAction: TextInputAction.done,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: busy ? null : submit,
        child: const Text('Request reset link'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => enterCustomerDemo(context, widget.store),
        child: const Text('Explore customer demo'),
      ),
    ],
  );
}
