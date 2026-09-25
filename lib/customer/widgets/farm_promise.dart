import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class FarmPromise extends StatelessWidget {
  const FarmPromise(this.icon, this.label, {super.key});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: green),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );
}
