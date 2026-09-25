import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/empty_state.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/price_row.dart';
import '../widgets/product_art.dart';
import '../widgets/quantity_picker.dart';
import '../widgets/surface.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: store,
    title: 'Your basket',
    child: ListenableBuilder(
      listenable: store,
      builder: (context, _) => PageFrame(
        title: 'Your basket',
        actions: [
          if (store.cart.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Empty your basket?'),
                    content: const Text(
                      'All items will be removed from your basket.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Keep items'),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Clear basket'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  store.clearCart();
                }
              },
              child: const Text('Clear all'),
            ),
        ],
        child: store.cart.isEmpty
            ? EmptyState(
                Icons.shopping_basket_outlined,
                'Your next fresh start',
                'Your basket is waiting for something delicious.',
                action: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Continue shopping'),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(22),
                children: [
                  Heading(
                    'A basket full of goodness',
                    subtitle:
                        '${store.cartCount} items from your local growers',
                  ),
                  ...store.cart.entries.map((e) {
                    final p = store.product(e.key);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Surface(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 68,
                              height: 82,
                              child: ProductArt(p, size: 37),
                            ),
                            const SizedBox(width: 13),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: green,
                                    ),
                                  ),
                                  Text(
                                    '${money(p.price)} / ${p.unit}',
                                    style: const TextStyle(color: muted),
                                  ),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 10,
                                    children: [
                                      QuantityPicker(
                                        value: e.value,
                                        max: store.stock(p),
                                        onChanged: (q) => store.quantity(p, q),
                                      ),
                                      Text(
                                        money(p.price * e.value),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove ${p.name}',
                              onPressed: () => store.quantity(p, 0),
                              icon: const Icon(Icons.close, size: 18),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 14),
                  Surface(
                    child: Column(
                      children: [
                        PriceRow('Subtotal', money(store.subtotal)),
                        const PriceRow('Pickup', 'Free'),
                        const Divider(),
                        PriceRow('Total', money(store.subtotal), bold: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'A simulated checkout. No payment will be collected.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () =>
                        openPage(context, CheckoutScreen(store: store)),
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Continue to checkout'),
                  ),
                ],
              ),
      ),
    ),
  );
}
