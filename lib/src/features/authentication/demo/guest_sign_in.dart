import 'package:flutter/material.dart';

import '../../common/shared/components.dart';

Future<void> requireGuestSignIn(
  BuildContext context, {
  bool addingToCart = false,
}) async {
  final store = HarvestScope.of(context);
  final signIn = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(
        addingToCart ? 'Sign in to add to cart' : 'Sign in to place your order',
      ),
      content: Text(
        addingToCart
            ? 'Browse products freely. Sign in or create an account to add products to your cart.'
            : 'Sign in or create an account to continue checkout.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Keep browsing'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Sign in / Create account'),
        ),
      ],
    ),
  );
  if (signIn == true && context.mounted) store.requestSignIn();
}

class GuestAccountPrompt extends StatelessWidget {
  const GuestAccountPrompt({super.key, this.title = 'Sign in to continue'});
  final String title;
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: title,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.person_outline, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            const Text(
              'Browse freely in demo mode. Sign in to access your account and place orders.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            HarvestButton(
              label: 'Sign in / Create account',
              onPressed: HarvestScope.of(context).requestSignIn,
            ),
          ],
        ),
      ),
    ),
  );
}
