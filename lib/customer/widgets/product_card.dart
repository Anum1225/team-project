import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../models/product.dart';
import '../screens/product_screen.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import 'product_art.dart';
import 'tag.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.store});
  final Product product;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () =>
          openPage(context, ProductScreen(product: product, store: store)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 135,
              child: Stack(
                children: [
                  Positioned.fill(child: ProductArt(product)),
                  if (product.organic)
                    const Positioned(
                      top: 9,
                      left: 8,
                      child: Tag('ORGANIC', color: Colors.white),
                    ),
                  Positioned(
                    top: 2,
                    right: 0,
                    child: IconButton(
                      tooltip: store.wishlist.contains(product.id)
                          ? 'Remove ${product.name} from wishlist'
                          : 'Save ${product.name}',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .85),
                      ),
                      onPressed: () => store.toggleWish(product.id),
                      icon: Icon(
                        store.wishlist.contains(product.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: green,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Text(
              product.farmer.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color: muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: green,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${product.category} · ${store.stock(product)} available',
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: muted),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: money(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: green,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${product.unit}',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                if (store.canShop)
                  IconButton.filled(
                    tooltip: 'Add ${product.name} to cart',
                    onPressed:
                        store.stock(product) <= (store.cart[product.id] ?? 0)
                        ? null
                        : () {
                            if (store.add(product)) {
                              toast(
                                context,
                                '${product.name} added to your basket',
                              );
                            }
                          },
                    icon: const Icon(Icons.add, size: 19),
                    style: IconButton.styleFrom(
                      minimumSize: const Size(36, 36),
                      padding: const EdgeInsets.all(7),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
