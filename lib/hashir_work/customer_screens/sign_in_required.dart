import 'package:flutter/material.dart';

import '../auth.dart';
import '../components.dart';
import '../models.dart';

class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key});
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Sign in to continue',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const PageHeading(
          'Enjoy browsing',
          subtitle: 'Demo visitors can explore products and save favorites. Sign in to shop, place orders and manage your account.',
        ),
        HarvestButton(
          label: 'Sign in',
          onPressed: () => openPage(
            context,
            AuthScreen(role: UserRole.customer, onPreview: (_) {}),
          ),
        ),
      ],
    ),
  );
}
