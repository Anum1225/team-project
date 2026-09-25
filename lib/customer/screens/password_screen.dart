import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/customer_form.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/password_field.dart';
import '../widgets/surface.dart';

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();

  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    try {
      await widget.store.changePassword(current.text, next.text);
      if (mounted) {
        toast(context, 'Password updated');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) toast(context, FirebaseCustomerService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: widget.store,
    title: 'Change password',
    child: PageFrame(
      title: 'Change password',
      child: CustomerForm(
        formKey: form,
        children: [
          const Heading(
            'Keep your account secure',
            subtitle: 'Choose a different password with a lowercase letter and a number.',
          ),
          const Surface(
            color: lime,
            child: Text(
              'Enter your current password to confirm this change.',
              style: TextStyle(color: green),
            ),
          ),
          const SizedBox(height: 24),
          PasswordField(
            controller: current,
            label: 'Current password',
            validator: CustomerValidators.currentPassword,
          ),
          const SizedBox(height: 18),
          PasswordField(
            controller: next,
            label: 'New password',
            newPassword: true,
            dependsOn: current,
            helperText:
                '8–128 characters, including a lowercase letter and a number.',
            validator: (v) =>
                CustomerValidators.newPassword(v, current: current.text),
          ),
          const SizedBox(height: 18),
          PasswordField(
            controller: confirm,
            label: 'Confirm new password',
            newPassword: true,
            dependsOn: next,
            validator: (v) => CustomerValidators.confirmPassword(v, next.text),
            onSubmitted: submit,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy ? null : submit,
            child: const Text('Update password'),
          ),
        ],
      ),
    ),
  );
}
