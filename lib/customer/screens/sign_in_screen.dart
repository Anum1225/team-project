import '../services/firebase_customer_service.dart';
import 'customer_shell.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../utils/demo_navigation.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    try {
      await widget.store.signIn(email.text.trim(), password.text);
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
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormFrame(
    busy: busy,
    title: 'Sign in',
    heading: 'Welcome back',
    subtitle: 'A little closer to fresh, local food.',
    formKey: form,
    children: [
      CustomerTextField(controller: email, kind: CustomerFieldKind.email),
      const SizedBox(height: 16),
      PasswordField(
        controller: password,
        label: 'Password',
        validator: CustomerValidators.currentPassword,
        onSubmitted: submit,
      ),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () =>
              openPage(context, ResetPasswordScreen(store: widget.store)),
          child: const Text('Forgot password?'),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton(
        onPressed: busy ? null : submit,
        child: const Text('Sign in'),
      ),
      const SizedBox(height: 12),
      OutlinedButton(
        onPressed: () => enterCustomerDemo(context, widget.store),
        child: const Text('Explore customer demo'),
      ),
      TextButton(
        onPressed: () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => RegisterScreen(store: widget.store),
          ),
        ),
        child: const Text('New here? Create an account'),
      ),
    ],
  );
}
