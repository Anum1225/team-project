import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = lime});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: green,
      ),
    ),
  );
}
