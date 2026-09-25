import 'package:flutter/material.dart';

import '../screens/sign_in_screen.dart';
import '../state/customer_store.dart';
import '../utils/navigation.dart';
import 'empty_state.dart';

class SignInRequired extends StatelessWidget {
  const SignInRequired({super.key, required this.store});
  final CustomerStore store;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: EmptyState(
      Icons.lock_outline,
      'You’re browsing in demo mode',
      'Explore products and save your favorites. Sign in to add items to your basket, place orders, or manage your account.',
      action: FilledButton.icon(
        onPressed: () => openPage(context, SignInScreen(store: store)),
        icon: const Icon(Icons.login),
        label: const Text('Sign in to continue'),
      ),
    ),
  );
}
