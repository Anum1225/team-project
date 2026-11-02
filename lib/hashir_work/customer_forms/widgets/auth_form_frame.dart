import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';
import 'customer_form.dart';
import 'heading.dart';
import 'page_frame.dart';

class AuthFormFrame extends StatelessWidget {
  const AuthFormFrame({
    super.key,
    required this.title,
    required this.heading,
    required this.subtitle,
    required this.formKey,
    required this.children,
    this.busy = false,
  });
  final bool busy;
  final String title, heading, subtitle;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Theme(
    data: customerTheme(),
    child: PopScope(
      canPop: !busy,
      child: AbsorbPointer(
        absorbing: busy,
        child: PageFrame(
          title: title,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 510),
              child: CustomerForm(
                formKey: formKey,
                children: [
                  const Icon(Icons.eco, color: green, size: 48),
                  const SizedBox(height: 22),
                  Heading(heading, subtitle: subtitle),
                  const SizedBox(height: 24),
                  if (busy) const LinearProgressIndicator(),
                  ...children,
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
