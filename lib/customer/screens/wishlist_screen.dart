import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/heading.dart';
import '../widgets/product_grid.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({
    super.key,
    required this.store,
    required this.onBrowse,
  });
  final CustomerStore store;
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => store.wishlist.isEmpty
      ? EmptyState(
          Icons.favorite_border,
          'Keep the good stuff close',
          'Save your favorite produce and come back when your basket needs a little fresh.',
          action: FilledButton(
            onPressed: onBrowse,
            child: const Text('Explore the harvest'),
          ),
        )
      : ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Heading(
              'Your wishlist',
              subtitle:
                  '${store.wishlist.length} favorites, saved for another day.',
            ),
            const Text(
              'Restock push alerts will be available when live services are connected.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            ProductGrid(
              items: products
                  .where((p) => store.wishlist.contains(p.id))
                  .toList(),
              store: store,
            ),
          ],
        );
}
