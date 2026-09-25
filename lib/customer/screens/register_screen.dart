import '../services/firebase_customer_service.dart';
import 'customer_shell.dart';
import '../models/customer_profile.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../utils/demo_navigation.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/password_field.dart';
import 'sign_in_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.store});
  final CustomerStore store;
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
    try {
      await widget.store.register(
        CustomerProfile(
          name: name.text.trim(),
          email: email.text.trim(),
          phone: CustomerValidators.normalizePhone(phone.text),
          address: address.text.trim(),
        ),
        password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => CustomerShell(store: widget.store)),
        (_) => false,
      );
    } catch (e) {
      if (mounted) toast(context, FirebaseCustomerService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
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
    busy: busy,
    title: 'Create account',
    heading: 'Join your local harvest',
    subtitle: 'A little closer to fresh, local food.',
    formKey: form,
    children: [
      CustomerTextField(controller: name, kind: CustomerFieldKind.name),
      const SizedBox(height: 16),
      CustomerTextField(controller: email, kind: CustomerFieldKind.email),
      const SizedBox(height: 16),
      CustomerTextField(
        controller: phone,
        kind: CustomerFieldKind.phone,
        helperText: 'Example: +92 300 1234567',
      ),
      const SizedBox(height: 16),
      CustomerTextField(controller: address, kind: CustomerFieldKind.address),
      const SizedBox(height: 16),
      PasswordField(
        controller: password,
        label: 'Password',
        newPassword: true,
        helperText:
            '8–128 characters, including a lowercase letter and a number.',
        validator: CustomerValidators.newPassword,
      ),
      const SizedBox(height: 16),
      PasswordField(
        controller: confirmation,
        label: 'Confirm password',
        newPassword: true,
        dependsOn: password,
        validator: (v) => CustomerValidators.confirmPassword(v, password.text),
        onSubmitted: submit,
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: busy ? null : submit,
        child: const Text('Create account'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => enterCustomerDemo(context, widget.store),
        child: const Text('Explore customer demo'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => SignInScreen(store: widget.store)),
        ),
        child: const Text('Already have an account? Sign in'),
      ),
    ],
  );
}
