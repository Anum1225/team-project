import 'package:cloud_firestore/cloud_firestore.dart';
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
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final statusColor = switch (order.status) {
      OrderStatus.completed => const Color(0xFF10B981),
      OrderStatus.pending => const Color(0xFFF59E0B),
      OrderStatus.ready => const Color(0xFF3B82F6),
      OrderStatus.confirmed => const Color(0xFF3B82F6),
      OrderStatus.cancelled => const Color(0xFFEF4444),
    };

    final statusLabel = switch (order.status) {
      OrderStatus.completed => 'Completed',
      OrderStatus.pending => 'Pending',
      OrderStatus.ready => 'Ready for pickup',
      OrderStatus.confirmed => 'Confirmed',
      OrderStatus.cancelled => 'Cancelled',
    };

    final orderNum = order.id.startsWith('#') ? order.id : '#${order.id}';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                // Top Row: #1024, Date, and Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            orderNum,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              color: palette.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateLabel(order.date),
                            style: TextStyle(
                              fontSize: 11,
                              color: palette.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3.5,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Customer / Farm Row with Avatar
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color:
                            (isCustomer
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF3B82F6))
                                .withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        (isCustomer ? order.farmName : order.customerName)
                                .isNotEmpty
                            ? (isCustomer
                                      ? order.farmName
                                      : order.customerName)[0]
                                  .toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isCustomer
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isCustomer ? order.farmName : order.customerName,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom Row: Produce Thumbnails + Price & View Details
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Produce Thumbnails
                    Expanded(
                      child: Row(
                        children: [
                          for (final item in order.items.take(3))
                            Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Photo(
                                  item.image,
                                  bytes: item.photo,
                                  width: 44,
                                  height: 44,
                                  radius: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Price, item count, and View Details
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          money(order.total),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: palette.ink,
                          ),
                        ),
                        Text(
                          '${order.items.fold<int>(0, (a, e) => a + e.quantity)} items',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        OutlinedButton(
                          onPressed:
                              onOpen ??
                              () => openPage(
                                context,
                                OrderDetailScreen(order: order),
                              ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: palette.border),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'View Details',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: palette.ink,
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 14,
                                color: palette.muted,
                              ),
                            ],
                          ),
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
    final palette = Harvest.colors(context);

    final allOrders = store.visibleOrders;
    final pendingCount = allOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final processingCount = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.ready,
        )
        .length;
    final completedCount = allOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final cancelledCount = allOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;

    final filterTabs = [
      ('All', 'All (${allOrders.length})'),
      ('Pending', 'Pending ($pendingCount)'),
      ('Processing', 'Processing ($processingCount)'),
      ('Completed', 'Completed ($completedCount)'),
      ('Cancelled', 'Cancelled ($cancelledCount)'),
    ];

    final orders = allOrders.where((o) {
      if (!'${o.id} ${o.customerName} ${o.customerId} ${o.farmName} ${o.farmId}'
          .toLowerCase()
          .contains(_query.toLowerCase().trim())) {
        return false;
      }
      if (_selected == 'All') return true;
      if (_selected == 'Pending') return o.status == OrderStatus.pending;
      if (_selected == 'Processing') {
        return o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.ready;
      }
      if (_selected == 'Completed') return o.status == OrderStatus.completed;
      if (_selected == 'Cancelled') return o.status == OrderStatus.cancelled;
      if (_selected == 'Active') return o.status.active;
      if (_selected == 'Past') return !o.status.active;
      return o.status.label == _selected;
    }).toList();

    if (_oldest) orders.sort((a, b) => a.date.compareTo(b.date));

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'Orders',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: _oldest ? 'Sorted: Oldest first' : 'Sorted: Newest first',
            icon: Icon(
              Icons.tune_rounded,
              color: _oldest ? palette.green : null,
            ),
            onPressed: () => setState(() => _oldest = !_oldest),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Filter Tabs matching Image 1 Screen 5 & Image 2 Screen 3
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in filterTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = tab.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selected == tab.$1
                              ? palette.green
                              : palette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selected == tab.$1
                                ? palette.green
                                : palette.border,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          tab.$2,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: _selected == tab.$1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _selected == tab.$1
                                ? Colors.white
                                : palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: palette.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search order #, customer or farm…',
                      hintStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: palette.muted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (v) => setState(() => _query = v),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: palette.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No orders in this view',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try changing your filter or search query.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
              ),
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
            style: TextStyle(
              color: Harvest.colors(context).muted,
              fontSize: 13,
            ),
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
                message:
                    'This order will be cancelled and items will be returned to inventory stock.',
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

  void _showPickupSheet(BuildContext context) {
    final store = HarvestScope.of(context);
    final slots = store.farm(order.farmId).pickupSlots;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => SheetBody(
        children: [
          Text('Select Pickup Window', style: Harvest.editorial(26)),
          if (slots.isEmpty)
            const InfoNote('This farmer has not published pickup windows yet.'),
          const SizedBox(height: 8),
          Text(
            'Reserve a convenient pickup slot with ${order.farmName}.',
            style: TextStyle(
              color: Harvest.colors(context).muted,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          for (final slot in slots) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: store.pickupSlot(order.id) == slot
                      ? Harvest.forest
                      : Harvest.colors(context).border,
                  width: store.pickupSlot(order.id) == slot ? 2 : 1,
                ),
                color: store.pickupSlot(order.id) == slot
                    ? Harvest.forest.withValues(alpha: 0.08)
                    : Harvest.colors(context).surface,
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                leading: Icon(
                  Icons.schedule_rounded,
                  color: store.pickupSlot(order.id) == slot
                      ? Harvest.forest
                      : Harvest.colors(context).muted,
                ),
                title: Text(
                  slot,
                  style: TextStyle(
                    fontWeight: store.pickupSlot(order.id) == slot
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                ),
                trailing: store.pickupSlot(order.id) == slot
                    ? const Icon(
                        Icons.check_circle_rounded,
                        color: Harvest.forest,
                      )
                    : null,
                onTap: () async {
                  Navigator.pop(sheet);
                  final err = await store.updatePickupSlot(order.id, slot);
                  if (context.mounted) {
                    notice(context, err ?? 'Pickup slot updated to $slot');
                  }
                },
              ),
            ),
          ],
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
      backgroundColor: Harvest.colors(context).cream,
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
            subtitle: 'Order ${order.id} · Placed on ${dateLabel(order.date)}',
          ),

          // Status & Timeline Progression
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Harvest.colors(context).surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.colors(context).border),
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
                                        : Harvest.colors(context).paleLeaf,
                                  ),
                                  child: Icon(
                                    isPast ? Icons.check : statusIcon(s),
                                    size: 16,
                                    color: isPast || isCurrent
                                        ? Colors.white
                                        : Harvest.colors(context).muted,
                                  ),
                                ),
                                if (i < timeline.length - 1)
                                  Container(
                                    width: 2,
                                    height: 28,
                                    color: isPast
                                        ? Harvest.forest
                                        : Harvest.colors(context).border,
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
                                        : Harvest.colors(context).ink,
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
                                  color: Harvest.colors(context).paleLeaf,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Current Status',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: Harvest.colors(context).green,
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
              color: Harvest.colors(context).surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.colors(context).border),
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
                                style: TextStyle(
                                  color: Harvest.colors(context).muted,
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
              color: Harvest.colors(context).surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.colors(context).border),
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
                    Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Harvest.colors(context).green,
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
                    Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Harvest.colors(context).green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        order.address,
                        style: TextStyle(color: Harvest.colors(context).muted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pickup Management (SRS Section 1.4 & 1.6: view, select, modify, or cancel bookings)
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Harvest.colors(context).surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.colors(context).border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Pickup Slot Booking',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (store.pickupSlot(order.id) != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Reserved',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: Harvest.colors(context).green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: store.live && store.role != UserRole.customer
                          ? StreamBuilder(
                              stream: FirebaseFirestore.instance
                                  .doc(
                                    'users/${order.customerId}/pickups/${order.id}',
                                  )
                                  .snapshots(),
                              builder: (context, snapshot) => Text(
                                snapshot.hasError
                                    ? 'Pickup booking could not load.'
                                    : snapshot.data?.data()?['slot']
                                              as String? ??
                                          'No pickup window booked yet.',
                              ),
                            )
                          : Text(
                              store.pickupSlot(order.id) ??
                                  'No pickup window booked yet.',
                              style: TextStyle(
                                fontWeight: store.pickupSlot(order.id) != null
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: store.pickupSlot(order.id) != null
                                    ? Harvest.colors(context).ink
                                    : Harvest.colors(context).muted,
                              ),
                            ),
                    ),
                  ],
                ),
                if (store.role == UserRole.customer && order.status.active) ...[
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _showPickupSheet(context),
                          icon: const Icon(
                            Icons.edit_calendar_outlined,
                            size: 16,
                          ),
                          label: Text(
                            store.pickupSlot(order.id) == null
                                ? 'Book Slot'
                                : 'Modify Slot',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Harvest.forest,
                            side: BorderSide(
                              color: Harvest.colors(context).border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      if (store.pickupSlot(order.id) != null) ...[
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () async {
                            final yes = await confirmAction(
                              context,
                              title: 'Cancel Pickup Booking?',
                              message:
                                  'This will release your reserved pickup slot.',
                              action: 'Cancel Slot',
                              isDestructive: true,
                            );
                            if (yes && context.mounted) {
                              final err = await store.updatePickupSlot(
                                order.id,
                                null,
                              );
                              if (context.mounted) {
                                notice(
                                  context,
                                  err ?? 'Pickup booking cancelled.',
                                );
                              }
                            }
                          },
                          child: const Text(
                            'Cancel Slot',
                            style: TextStyle(
                              color: Harvest.danger,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
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
