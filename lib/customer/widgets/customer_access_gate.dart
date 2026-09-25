import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import 'page_frame.dart';
import 'sign_in_required.dart';

/// Also protects pages opened directly, not just links in the customer shell.
class CustomerAccessGate extends StatelessWidget {
  const CustomerAccessGate({
    super.key,
    required this.store,
    required this.child,
    this.title,
  });
  final CustomerStore store;
  final Widget child;
  final String? title;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => store.canShop
        ? child
        : title == null
        ? SignInRequired(store: store)
        : PageFrame(
            title: title!,
            child: SignInRequired(store: store),
          ),
  );
}
