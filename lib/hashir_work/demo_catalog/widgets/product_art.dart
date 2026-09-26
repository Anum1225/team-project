import 'package:flutter/material.dart';

import '../models/product.dart';
import 'produce_illustration.dart';

class ProductArt extends StatelessWidget {
  const ProductArt(this.product, {super.key, this.size = 70});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Color(product.color),
      borderRadius: BorderRadius.circular(15),
    ),
    alignment: Alignment.center,
    child: Semantics(
      label: product.name,
      image: true,
      child: ProduceIllustration(id: product.id, size: size),
    ),
  );
}
