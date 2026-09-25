import 'package:flutter/material.dart';

import '../models/product.dart';
import '../state/customer_store.dart';
import 'product_card.dart';

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.items, required this.store});
  final List<Product> items;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth > 850
          ? 4
          : box.maxWidth > 570
          ? 3
          : box.maxWidth < 300
          ? 1
          : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          mainAxisExtent: 294,
        ),
        itemBuilder: (context, i) =>
            ProductCard(product: items[i], store: store),
      );
    },
  );
}
