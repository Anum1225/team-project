import 'package:flutter/material.dart';

import 'components.dart';
import 'models.dart';
import 'theme.dart';

IconData statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.pending => Icons.schedule,
  OrderStatus.confirmed => Icons.task_alt,
  OrderStatus.ready => Icons.storefront_outlined,
  OrderStatus.completed => Icons.check_circle_outline,
  OrderStatus.cancelled => Icons.cancel_outlined,
};

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order, this.onOpen});
  final HarvestOrder order;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final isCustomer = store.role == UserRole.customer;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Harvest.border),
        boxShadow: Harvest.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap:
              onOpen ??
              () => openPage(context, OrderDetailScreen(order: order)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.id,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      dateLabel(order.date),
                      style: const TextStyle(
                        fontSize: 12,
                        color: Harvest.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isCustomer ? order.farmName : order.customerName,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Harvest.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                // Thumbnails cluster
                Row(
                  children: [
                    for (final item in order.items.take(3))
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Photo(
                          item.image,
                          bytes: item.photo,
                          width: 48,
                          height: 48,
                          radius: 10,
                        ),
                      ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${order.items.fold<int>(0, (a, e) => a + e.quantity)} items',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Harvest.muted,
                          ),
                        ),
                        Text(
                          money(order.total),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Harvest.forest,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    StatusBadge(
                      order.status.label,
                      warning: order.status == OrderStatus.pending,
                      success: order.status == OrderStatus.completed,
                      icon: statusIcon(order.status),
                    ),
                    const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Harvest.forest,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Harvest.forest,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String _query = "";
  bool _oldest = false;
  String _selected = 'Active';

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final customer = store.role == UserRole.customer;
    final choices = customer
        ? ['Active', 'Past']
        : ['Active', ...OrderStatus.values.map((s) => s.label), 'All'];

    final orders = store.visibleOrders.where((o) {
      if (!'${o.id} ${o.customerName} ${o.customerId} ${o.farmName} ${o.farmId}'
          .toLowerCase()
          .contains(_query.toLowerCase().trim())) {
        return false;
      }
      if (_selected == 'All') return true;
      if (_selected == 'Active') return o.status.active;
      if (_selected == 'Past') return !o.status.active;
      return o.status.label == _selected;
    }).toList();

    if (_oldest) orders.sort((a, b) => a.date.compareTo(b.date));
    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        title: Text(
          customer ? 'Your Harvest Orders' : 'Order Management',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          PageHeading(
            customer ? 'Your Harvests' : 'Orders to Tend',
            eyebrow: customer ? 'Farm to Table' : 'Order Operations',
            subtitle: customer
                ? 'Track your fresh produce shipments and order history.'
                : 'Manage customer orders and advance harvest statuses.',
          ),
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search order, customer or farm',
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
          SwitchListTile(
            title: const Text('Oldest first'),
            value: _oldest,
            onChanged: (v) => setState(() => _oldest = v),
          ),
          ChoiceRow(
            values: choices,
            selected: _selected,
            onSelected: (v) => setState(() => _selected = v),
          ),
          const SizedBox(height: 20),
          if (orders.isEmpty)
            EmptyState(
              title: customer
                  ? 'Your next harvest is waiting'
                  : 'All caught up',
              message: customer
                  ? 'You have no $_selected orders right now. Explore our catalog of fresh farm produce.'
                  : 'No orders under this filter right now.',
              icon: Icons.receipt_long_outlined,
            )
          else
            for (final o in orders) OrderCard(order: o),
        ],
      ),
    );
  }
}

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.order});
  final HarvestOrder order;

  void _showUpdateSheet(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!order.status.active) return;
    final next = OrderStatus.values[order.status.index + 1];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SheetBody(
        children: [
          Text('Advance Order', style: Harvest.editorial(26)),
          const SizedBox(height: 8),
          Text(
            'Move order ${order.id} to next status: "${next.label}".',
            style: const TextStyle(color: Harvest.muted, fontSize: 13),
          ),
          const SizedBox(height: 20),
          HarvestButton(
            label: 'Mark as ${next.label}',
            icon: statusIcon(next),
            onPressed: store.busy
                ? null
                : () async {
                    final err = await store.updateStatus(order, next);
                    if (!context.mounted || !sheet.mounted) return;
                    Navigator.pop(sheet);
                    notice(context, err ?? 'Order marked as ${next.label}');
                  },
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () async {
              Navigator.pop(sheet);
              final yes = await confirmAction(
                context,
                title: 'Cancel this order?',
                message: 'This order will be cancelled and items will be returned to inventory stock.',
                action: 'Confirm Cancellation',
                isDestructive: true,
              );
              if (yes && context.mounted) {
                final err = await store.updateStatus(
                  order,
                  OrderStatus.cancelled,
                );
                if (!context.mounted) return;
                notice(context, err ?? 'Order cancelled. Inventory restored.');
              }
            },
            child: const Text(
              'Cancel Order',
              style: TextStyle(color: Harvest.danger),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final canUpdate = store.role != UserRole.customer && order.status.active;
    final timeline = OrderStatus.values
        .where((s) => s != OrderStatus.cancelled)
        .toList();

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        title: Text(
          'Order ${order.id}',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          PageHeading(
            order.status == OrderStatus.completed
                ? 'Harvest Delivered'
                : order.status == OrderStatus.cancelled
                ? 'Order Cancelled'
                : 'Harvest in Progress',
            eyebrow: order.farmName,
            subtitle: 'Placed on ${dateLabel(order.date)}',
          ),

          // Status & Timeline Progression
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Progress Timeline',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 16),
                if (order.status == OrderStatus.cancelled)
                  const InfoNote(
                    'This order was cancelled. Items have been restocked to farmer inventory.',
                    error: true,
                  )
                else
                  for (var i = 0; i < timeline.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final s = timeline[i];
                        final isPast = s.index < order.status.index;
                        final isCurrent = s == order.status;
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isPast || isCurrent
                                        ? Harvest.forest
                                        : Harvest.sage,
                                  ),
                                  child: Icon(
                                    isPast ? Icons.check : statusIcon(s),
                                    size: 16,
                                    color: isPast || isCurrent
                                        ? Colors.white
                                        : Harvest.muted,
                                  ),
                                ),
                                if (i < timeline.length - 1)
                                  Container(
                                    width: 2,
                                    height: 28,
                                    color: isPast
                                        ? Harvest.forest
                                        : Harvest.border,
                                  ),
                              ],
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  s.label,
                                  style: TextStyle(
                                    fontWeight: isCurrent
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                    color: isCurrent
                                        ? Harvest.forest
                                        : Harvest.ink,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                            if (isCurrent)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Harvest.sage,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Current Status',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Harvest.forest,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Purchased Harvest Items
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Harvest Items',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 14),
                for (final line in order.items) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Photo(
                          line.image,
                          bytes: line.photo,
                          width: 52,
                          height: 52,
                          radius: 10,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                line.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${line.quantity} × ${line.unit}',
                                style: const TextStyle(
                                  color: Harvest.muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          money(line.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      money(order.total),
                      style: Harvest.editorial(22, color: Harvest.forest),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Delivery info
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Delivery & Customer Info',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Harvest.forest,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      order.customerName,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Harvest.forest,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address,
                        style: const TextStyle(color: Harvest.muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: canUpdate
          ? BottomAction(
              child: HarvestButton(
                label: 'Advance Order Status',
                icon: Icons.sync,
                onPressed: () => _showUpdateSheet(context),
              ),
            )
          : null,
    );
  }
}
