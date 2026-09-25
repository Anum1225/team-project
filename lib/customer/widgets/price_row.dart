import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class PriceRow extends StatelessWidget {
  const PriceRow(this.label, this.value, {super.key, this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? green : muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 21 : 15,
            color: green,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
