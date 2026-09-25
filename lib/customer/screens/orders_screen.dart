import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/empty_state.dart';
import '../widgets/heading.dart';
import '../widgets/surface.dart';
import '../widgets/tag.dart';
import 'order_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.store, required this.onBrowse});
  final CustomerStore store;
  final VoidCallback onBrowse;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final orders = widget.store.orders
        .where(
          (o) =>
              filter == 'All' ||
              (filter == 'Active'
                  ? !['Completed', 'Cancelled'].contains(o.status)
                  : o.status == filter),
        )
        .toList();
    return CustomerAccessGate(
      store: widget.store,
      child: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          const Heading(
            'Your orders',
            subtitle: 'Every basket has a story. Here are yours.',
          ),
          Wrap(
            spacing: 8,
            children: ['All', 'Active', 'Completed', 'Cancelled']
                .map(
                  (s) => ChoiceChip(
                    label: Text(s),
                    selected: filter == s,
                    onSelected: (_) => setState(() => filter = s),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          if (orders.isEmpty)
            EmptyState(
              Icons.receipt_long_outlined,
              'No orders here yet',
              'Your orders and pickup bookings will appear here after checkout.',
              action: FilledButton(
                onPressed: widget.onBrowse,
                child: const Text('Find something fresh'),
              ),
            ),
          ...orders.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            o.id,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: green,
                            ),
                          ),
                        ),
                        Tag(o.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      dateLabel(o.date),
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      o.lines
                          .map((l) => '${l.product.name} × ${l.quantity}')
                          .join(' · '),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            money(o.total),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 19,
                              color: green,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => openPage(
                            context,
                            OrderScreen(store: widget.store, order: o),
                          ),
                          child: const Text('View details'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
