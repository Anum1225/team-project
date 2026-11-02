part of 'orders.dart';

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
            'Request a convenient pickup window with ${order.farmName}.',
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
    final order =
        store.orders.where((o) => o.id == this.order.id).firstOrNull ??
        this.order;
    final canUpdate =
        store.role != UserRole.customer &&
        order.approvalStatus == 'approved' &&
        order.status.active;
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
            order.approvalStatus == 'pending'
                ? 'Awaiting Admin Approval'
                : order.approvalStatus == 'rejected'
                ? 'Order Not Approved'
                : order.status == OrderStatus.completed
                ? 'Harvest Delivered'
                : order.status == OrderStatus.cancelled
                ? 'Order Cancelled'
                : 'Harvest in Progress',
            eyebrow: order.farmName,
            subtitle: store.role == UserRole.customer
                ? 'Placed on ${dateLabel(order.date)}'
                : 'Order ${order.id} · Placed on ${dateLabel(order.date)}',
          ),

          if (store.role == UserRole.customer) ...[
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Harvest.colors(context).paleLeaf,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.calendar_month_outlined,
                  color: Harvest.colors(context).forest,
                ),
              ),
              title: Text(
                store.pickupSlot(order.id) == null
                    ? 'Book a pickup'
                    : 'Your pickup',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(store.pickupSlot(order.id) ?? order.farmName),
              trailing: order.status.active
                  ? const Icon(Icons.chevron_right)
                  : null,
              onTap: order.status.active
                  ? () => _showPickupSheet(context)
                  : null,
            ),
            if (order.status.active && store.pickupSlot(order.id) != null)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () async {
                    final yes = await confirmAction(
                      context,
                      title: 'Cancel Pickup Booking?',
                      message: 'This will remove your requested pickup window.',
                      action: 'Cancel Slot',
                      isDestructive: true,
                    );
                    if (!yes || !context.mounted) return;
                    final error = await store.updatePickupSlot(order.id, null);
                    if (context.mounted) {
                      notice(context, error ?? 'Pickup booking cancelled.');
                    }
                  },
                  child: const Text('Cancel Slot'),
                ),
              ),
            const SizedBox(height: 16),
          ],

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
                          line.displayImage,
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
                Text(
                  store.role == UserRole.customer
                      ? 'Delivery & Customer Info'
                      : 'Customer contact details',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
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
                    Expanded(
                      child: Text(
                        store.role == UserRole.customer
                            ? order.contactName
                            : order.customerName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
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
                if (store.role == UserRole.customer) ...[
                  const SizedBox(height: 10),
                  _contactRow(
                    context,
                    Icons.phone_outlined,
                    order.phone.isEmpty
                        ? 'Phone not recorded for this order'
                        : order.phone,
                  ),
                  const SizedBox(height: 10),
                  _contactRow(
                    context,
                    Icons.payments_outlined,
                    'Cash on Delivery',
                  ),
                  if (order.note.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Note for the farmer',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.note,
                      style: TextStyle(color: Harvest.colors(context).muted),
                    ),
                  ],
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Pickup Management (SRS Section 1.4 & 1.6: view, select, modify, or cancel bookings)
          if (store.role != UserRole.customer)
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
                            color: const Color(0xFF16A34A)
                                .withValues(alpha: 0.12),
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
                  if (store.role == UserRole.customer &&
                      order.status.active) ...[
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
                                message: 'This will remove your requested pickup window.',
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

  Widget _contactRow(BuildContext context, IconData icon, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: Harvest.colors(context).green),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(color: Harvest.colors(context).muted),
        ),
      ),
    ],
  );
}
