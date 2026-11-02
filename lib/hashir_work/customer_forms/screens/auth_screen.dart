import 'package:flutter/material.dart';

import '../../components.dart';
import '../../models.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/auth_form_frame.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';
import 'password_help_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role, required this.onPreview});
  final UserRole role;
  final ValueChanged<UserRole> onPreview;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  Future<void> submit() async {
    if (busy || !validateCustomerForm(form)) return;
    setState(() => busy = true);
    final result = await HarvestScope.of(context)
        .signIn(email.text.trim(), password.text, widget.role);
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
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AuthFormFrame(
    title: 'Sign in',
    heading: 'Welcome back',
    subtitle: 'A little closer to fresh, local food.',
    formKey: form,
    busy: busy,
    children: [
      CustomerTextField(controller: email, kind: CustomerFieldKind.email),
      const SizedBox(height: 16),
      PasswordField(
        controller: password,
        label: 'Password',
        validator: CustomerValidators.currentPassword,
        onSubmitted: submit,
      ),
      const SizedBox(height: 8),
      Align(
        alignment: Alignment.centerRight,
        child: TextButton(
          onPressed: () => openPage(context, const PasswordHelpScreen()),
          child: const Text('Forgot password?'),
        ),
      ),
      const SizedBox(height: 24),
      FilledButton(onPressed: submit, child: const Text('Sign in')),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: () => openPage(
          context,
          RegisterScreen(role: UserRole.customer, onPreview: widget.onPreview),
        ),
        child: const Text('Create account'),
      ),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: () {
          final enter = widget.onPreview;
          Navigator.of(context).popUntil((r) => r.isFirst);
          enter(UserRole.customer);
        },
        child: const Text('Explore customer demo'),
      ),
    ],
  );
}
