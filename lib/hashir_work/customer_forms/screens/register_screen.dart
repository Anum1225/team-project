import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({
    super.key,
    required this.role,
    required this.onPreview,
  });
  final UserRole role;
  final ValueChanged<UserRole> onPreview;
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    final result = await HarvestScope.of(context).register(
      email.text.trim(),
      password.text,
      name.text.trim(),
      CustomerValidators.normalizePhone(phone.text),
      address.text.trim(),
      widget.role,
    );
    if (!mounted) return;
    setState(() => busy = false);
    if (result != null) {
      notice(context, result, isError: true);
    } else {
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  @override
  void dispose() {
    for (final c in [name, email, phone, address, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormFrame(
    title: 'Create account',
    heading: 'Join your local harvest',
    subtitle: 'A little closer to fresh, local food.',
    formKey: form,
    busy: busy,
    children: [
      CustomerTextField(controller: name, kind: CustomerFieldKind.name),
      const SizedBox(height: 20),
      CustomerTextField(controller: email, kind: CustomerFieldKind.email),
      const SizedBox(height: 20),
      CustomerTextField(
        controller: phone,
        kind: CustomerFieldKind.phone,
        helperText: 'Example: +92 300 1234567',
      ),
      const SizedBox(height: 20),
      PasswordField(
        controller: password,
        label: 'Password',
        newPassword: true,
        validator: CustomerValidators.newPassword,
        helperText:
            '8–128 characters, including a lowercase letter and a number.',
      ),
      const SizedBox(height: 20),
      PasswordField(
        controller: confirmation,
        label: 'Confirm password',
        newPassword: true,
        dependsOn: password,
        validator: (v) => CustomerValidators.confirmPassword(v, password.text),
        onSubmitted: submit,
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: submit, child: const Text('Create account')),
      const SizedBox(height: 14),
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Already have an account? Sign in'),
      ),
    ],
  );
}
