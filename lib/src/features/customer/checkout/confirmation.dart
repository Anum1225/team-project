import 'package:flutter/material.dart';

import '../../common/data/models.dart';
import '../../common/shared/components.dart';
import '../../common/shared/theme.dart';
import '../../common/orders/orders.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.orders});
  final List<HarvestOrder> orders;

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final total = orders.fold<int>(0, (sum, order) => sum + order.total);
    final awaitingApproval = orders.any(
      (order) => order.approvalStatus == 'pending',
    );
    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 24),
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.green.withValues(alpha: .10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: palette.green.withValues(alpha: .15),
                    width: 6,
                  ),
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: palette.green,
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              awaitingApproval ? 'Order submitted' : 'Order confirmed',
              textAlign: TextAlign.center,
              style: Harvest.editorial(32),
            ),
            const SizedBox(height: 10),
            Text(
              awaitingApproval
                  ? 'Your order is awaiting administrator approval. You can follow its status from My Orders.'
                  : 'Thank you for supporting local growers. Follow your order status for confirmation and pickup updates.',
              textAlign: TextAlign.center,
              style: TextStyle(color: palette.muted, height: 1.5),
            ),
            const SizedBox(height: 26),
            for (final order in orders)
              Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: palette.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: palette.border),
                  boxShadow: Harvest.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: palette.green,
                          size: 22,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            order.farmName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SelectableText(
                      'Order ${order.id}',
                      style: TextStyle(fontSize: 12, color: palette.muted),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(),
                    ),
                    for (final item in order.items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Photo(
                              item.displayImage,
                              width: 44,
                              height: 44,
                              radius: 10,
                              label: item.name,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '×${item.quantity}',
                              style: TextStyle(color: palette.muted),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Order total',
                            style: TextStyle(color: palette.muted),
                          ),
                        ),
                        Text(
                          money(order.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: palette.green,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            if (orders.length > 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Row(
                  children: [
                    const Expanded(child: Text('Combined total')),
                    Text(
                      money(total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            const InfoNote(
              'Pickup only. Choose or review your pickup window from the order details. Checkout is simulated; no online payment was charged.',
              icon: Icons.shopping_bag_outlined,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              HarvestButton(
                label: 'View Order Status',
                onPressed: () => Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const OrdersScreen()),
                ),
              ),
              TextButton(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
