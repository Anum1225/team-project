import '../services/firebase_customer_service.dart';
import 'navigation.dart';

import 'package:flutter/material.dart';

import '../screens/customer_shell.dart';
import '../state/customer_store.dart';

Future<void> enterCustomerDemo(
  BuildContext context,
  CustomerStore store,
) async {
  try {
    await store.startDemo();
  } catch (e) {
    if (context.mounted) {
      toast(context, FirebaseCustomerService.errorMessage(e));
    }
    return;
  }
  if (!context.mounted) return;
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => CustomerShell(store: store)),
    (_) => false,
  );
}
