import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../models/customer_order.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/price_row.dart';
import '../widgets/product_art.dart';
import '../widgets/surface.dart';
import '../widgets/tag.dart';
import 'pickup_screen.dart';

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.store, required this.order});
  final CustomerStore store;
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: store,
    title: 'Order details',
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) => PageFrame(
        title: 'Order ${order.id}',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Heading(
              'Your harvest, on its way',
              subtitle: 'Placed ${dateLabel(order.date)} · Simulated order',
              trailing: Tag(order.status),
            ),
            Surface(
              child: Column(
                children:
                    ['Pending', 'Confirmed', 'Ready for Pickup', 'Completed']
                        .map(
                          (s) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              order.status == s
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_unchecked,
                              color: order.status == s ? green : muted,
                            ),
                            title: Text(s),
                            trailing: order.status == s
                                ? const Tag('Current')
                                : null,
                          ),
                        )
                        .toList(),
              ),
            ),
            const SizedBox(height: 24),
            const Heading('In your basket'),
            ...order.lines.map(
              (l) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: SizedBox(
                  width: 50,
                  height: 50,
                  child: ProductArt(l.product, size: 28),
                ),
                title: Text(l.product.name),
                subtitle: Text(
                  '${l.quantity} × ${money(l.product.price)} / ${l.product.unit}',
                ),
                trailing: Text(money(l.total)),
              ),
            ),
            const Divider(),
            PriceRow('Total', money(order.total), bold: true),
            const SizedBox(height: 24),
            const Heading('Pickup bookings'),
            ...order.lines.map((l) => l.product.farmerId).toSet().map((id) {
              final f = farmers.firstWhere((f) => f.id == id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        f.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text('${f.market} · ${f.location}'),
                      const SizedBox(height: 10),
                      Text(
                        order.pickups[id] ?? 'No pickup booked',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 12),
                      if (!['Completed', 'Cancelled'].contains(order.status))
                        OutlinedButton.icon(
                          onPressed: () => openPage(
                            context,
                            PickupScreen(store: store, order: order, farmer: f),
                          ),
                          icon: const Icon(Icons.edit_calendar_outlined),
                          label: Text(
                            order.pickups.containsKey(id)
                                ? 'Manage booking'
                                : 'Book a pickup',
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }),
            const Heading('Contact address'),
            Surface(
              child: Text(order.address, style: const TextStyle(height: 1.6)),
            ),
          ],
        ),
      ),
    ),
  );
}
