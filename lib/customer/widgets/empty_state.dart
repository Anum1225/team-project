import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.icon,
    this.title,
    this.message, {
    super.key,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: lime,
            child: Icon(icon, size: 40, color: green),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.6),
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 22), child: action!),
        ],
      ),
    ),
  );
}
