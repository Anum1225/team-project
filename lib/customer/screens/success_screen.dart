import 'package:flutter/material.dart';

import '../models/customer_order.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/page_frame.dart';
import '../widgets/price_row.dart';
import '../widgets/surface.dart';
import 'order_screen.dart';

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.order, required this.store});
  final CustomerOrder order;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: store,
    title: 'Order details',
    child: PageFrame(
      title: 'Order placed',
      child: ListView(
        padding: const EdgeInsets.all(30),
        children: [
          const SizedBox(height: 25),
          const CircleAvatar(
            radius: 52,
            backgroundColor: lime,
            child: Icon(Icons.check_rounded, size: 55, color: green),
          ),
          const SizedBox(height: 25),
          const Text(
            'Good things are growing.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 30,
              color: green,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your simulated order ${order.id} has been placed.\nThank you for supporting your local growers.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.7),
          ),
          const SizedBox(height: 28),
          Surface(
            child: Column(
              children: [
                PriceRow('Order number', order.id),
                PriceRow('Placed on', dateLabel(order.date)),
                const PriceRow('Status', 'Pending'),
                PriceRow('Total', money(order.total), bold: true),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => OrderScreen(store: store, order: order),
              ),
            ),
            child: const Text('View order & pickup details'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('Continue shopping'),
          ),
        ],
      ),
    ),
  );
}
