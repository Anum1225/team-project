part of 'orders.dart';

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

    final orderNum = isCustomer && order.id.length > 8
        ? '#${order.id.substring(order.id.length - 8).toUpperCase()}'
        : order.id.startsWith('#')
        ? order.id
        : '#${order.id}';

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
                                  item.displayImage,
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
