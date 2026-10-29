part of '../management/operations.dart';

class InventoryRow extends StatelessWidget {
  const InventoryRow({super.key, required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final inStock = p.stock > 5;
    final lowStock = p.stock > 0 && p.stock <= 5;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Harvest.colors(context).surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Harvest.colors(context).border),
        boxShadow: Harvest.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => openPage(context, ProductEditorScreen(product: p)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Photo(
                    p.displayImage,
                    bytes: p.photo,
                    width: 74,
                    height: 74,
                    radius: 14,
                    label: p.name,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              p.name,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: inStock
                                  ? const Color(0xFFDCFCE7)
                                  : (lowStock
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFFFEE2E2)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              inStock
                                  ? 'In Stock'
                                  : (lowStock ? 'Low Stock' : 'Out of Stock'),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: inStock
                                    ? const Color(0xFF16A34A)
                                    : (lowStock
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFFDC2626)),
                              ),
                            ),
                          ),
                          PopupMenuButton<String>(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              size: 18,
                              color: Harvest.colors(context).muted,
                            ),
                            onSelected: (val) {
                              if (val == 'edit') {
                                openPage(
                                  context,
                                  ProductEditorScreen(product: p),
                                );
                              } else if (val == 'delete') {
                                HarvestScope.of(context).deleteProduct(p);
                              }
                            },
                            itemBuilder: (ctx) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Text('Edit Product'),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Rs. ${(p.price / 100).toStringAsFixed(0)} / ${p.unit}',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 8,
                        runSpacing: 2,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'Stock: ${p.stock} ${p.unit}',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Harvest.colors(context).muted,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.visibility_outlined,
                                size: 13,
                                color: Harvest.colors(context).muted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${250 + (p.price % 100)}',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Harvest.colors(context).muted,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Icon(
                                Icons.shopping_cart_outlined,
                                size: 13,
                                color: Harvest.colors(context).muted,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${15 + (p.stock % 20)}',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Harvest.colors(context).muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
