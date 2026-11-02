part of '../customer.dart';

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Skip basket lines whose product is no longer loaded (archived/removed).
    final items = [
      for (final e in store.basket.entries)
        if (store.product(e.key) case final p?) (p, e.value),
    ];

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: const Text(
          'My Cart',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              tooltip: 'Clear Cart',
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Harvest.danger,
              ),
              onPressed: () => store.clearBasket(),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your cart is empty',
              message: 'Browse our local growers to discover fruits, vegetables, and pantry items harvested fresh today.',
              action: 'Start Shopping',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
              children: [
                for (final (p, qty) in items) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Harvest.colors(context).surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Harvest.colors(context).border),
                      boxShadow: Harvest.cardShadow,
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () =>
                              openPage(context, ProductScreen(product: p)),
                          borderRadius: BorderRadius.circular(14),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Photo(
                              p.displayImage,
                              bytes: p.photo,
                              width: 68,
                              height: 68,
                              radius: 14,
                              label: p.name,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              InkWell(
                                onTap: () => openPage(
                                  context,
                                  ProductScreen(product: p),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  child: Text(
                                    p.name,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14.5,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Rs. ${(p.price / 100).toStringAsFixed(0)} / ${p.unit}',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  color: Harvest.colors(context).muted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              QuantityStepper(
                                value: qty,
                                max: p.stock,
                                onChanged: (newQty) =>
                                    store.setQuantity(p.id, newQty),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Harvest.colors(context).muted,
                              ),
                              onPressed: () => store.setQuantity(p.id, 0),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              money(p.price * qty),
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],

                // "+ Add More Items - Explore more fresh products >" button matching Image 3 Screen 5
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Harvest.colors(context).surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF16A34A).withValues(alpha: 0.4),
                          width: 1.2,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 20,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Add More Items',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                                Text(
                                  'Explore more fresh products from local farms',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF16A34A),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Order summary breakdown matching Image 3 Screen 5
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Harvest.colors(context).surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Harvest.colors(context).border),
                    boxShadow: Harvest.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Order Summary',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Subtotal',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: Harvest.colors(context).muted,
                              fontSize: 13,
                            ),
                          ),
                          Text(
                            money(store.basketTotal),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Pickup',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: Harvest.colors(context).muted,
                              fontSize: 13,
                            ),
                          ),
                          const Text(
                            'Requested',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            money(store.basketTotal),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w900,
                              fontSize: 18,
                              color: Color(0xFF1E5631),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Delivery / Pickup Info Card matching Image 3 Screen 5
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF14241B)
                        : const Color(0xFFE8F5EE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.local_shipping_outlined,
                        color: Color(0xFF16A34A),
                        size: 22,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Farm pickup',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1E5631),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Request a pickup window when confirming your order.',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: Color(0xFF3D7A44),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : BottomAction(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => store.isDemo
                      ? requireGuestSignIn(context)
                      : openPage(context, const CheckoutScreen()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E5631),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Continue to Checkout · ${money(store.basketTotal)}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
