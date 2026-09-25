import 'package:flutter/material.dart';

class QuantityPicker extends StatelessWidget {
  const QuantityPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = 0,
  });
  final int value, max, min;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Decrease quantity',
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      IconButton(
        tooltip: 'Increase quantity',
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}
