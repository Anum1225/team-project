import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../models/product.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../widgets/farmer_tile.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/product_art.dart';
import '../widgets/quantity_picker.dart';
import '../widgets/surface.dart';
import '../widgets/tag.dart';
import 'cart_screen.dart';
import 'sign_in_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product, required this.store});
  final Product product;
  final CustomerStore store;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final p = widget.product, store = widget.store;
      final available = store.stock(p) - (store.cart[p.id] ?? 0);
      return PageFrame(
        title: 'Fresh from the farm',
        actions: [
          IconButton(
            tooltip: 'Shopping cart',
            onPressed: () => openPage(context, CartScreen(store: store)),
            icon: Badge(
              label: Text('${store.cartCount}'),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: 280, child: ProductArt(p, size: 145)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              children: [
                Tag(p.category),
                if (p.organic) const Tag('Organically grown'),
                Tag(
                  store.stock(p) > 0
                      ? '${store.stock(p)} in stock'
                      : 'Out of stock',
                ),
              ],
            ),
            Heading(
              p.name,
              subtitle: p.farmer.name,
              trailing: IconButton(
                tooltip: 'Toggle wishlist',
                onPressed: () => store.toggleWish(p.id),
                icon: Icon(
                  store.wishlist.contains(p.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
            Text(
              '${money(p.price)} / ${p.unit}',
              style: const TextStyle(
                fontSize: 26,
                color: green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              p.description,
              style: const TextStyle(color: muted, height: 1.8, fontSize: 16),
            ),
            const Divider(),
            FarmerTile(farmer: p.farmer, store: store),
            const SizedBox(height: 24),
            Surface(
              color: lime,
              child: Text(
                store.isDemo
                    ? 'Demo mode · Browse products and save favorites. Sign in to add items to your basket and place orders.'
                    : 'A fresher way to shop\nChoose a pickup time at checkout. Orders in this preview are simulated.',
                style: const TextStyle(color: green, height: 1.7),
              ),
            ),
            const SizedBox(height: 20),
            if (store.isDemo)
              FilledButton.icon(
                onPressed: () => openPage(context, SignInScreen(store: store)),
                icon: const Icon(Icons.login),
                label: const Text('Sign in to shop'),
              )
            else
              Wrap(
                spacing: 20,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  QuantityPicker(
                    value: quantity,
                    min: 1,
                    max: available,
                    onChanged: (v) => setState(() => quantity = v),
                  ),
                  FilledButton.icon(
                    onPressed: available < quantity
                        ? null
                        : () {
                            if (store.add(p, quantity)) {
                              toast(context, 'Added to your basket');
                              setState(() => quantity = 1);
                            }
                          },
                    icon: const Icon(Icons.shopping_basket_outlined),
                    label: Text(
                      available <= 0
                          ? 'Unavailable'
                          : 'Add to basket · ${money(p.price * quantity)}',
                    ),
                  ),
                ],
              ),
          ],
        ),
      );
    },
  );
}
