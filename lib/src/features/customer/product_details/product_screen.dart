part of '../customer.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, this.product, this.productId});
  final Product? product;
  final String? productId;

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int _quantity = 1;
  int _selectedThumbnail = 0;
  bool _isDescriptionExpanded = false;
  String? _selectedOfferId;

  Widget _trustBadge(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _nutritionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Harvest.colors(context).surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Harvest.colors(context).border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    color: Harvest.colors(context).muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final p =
        (_selectedOfferId == null ? null : store.product(_selectedOfferId!)) ??
        widget.product ??
        (widget.productId != null ? store.product(widget.productId!) : null);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Details')),
        body: const Center(child: Text('Product not found')),
      );
    }
    final farm = store.farm(p.farmId);
    final offers = store.offersFor(p);
    final isSaved = store.saved.contains(p.id);
    final relatedProducts = store.visibleProducts
        .where((item) => store.catalogKey(item) != store.catalogKey(p))
        .take(4)
        .toList();

    final thumbnails = [p.displayImage];

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14),
          child: Center(
            child: CircularNavButton(
              icon: Icons.arrow_back,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: Text(
          'Product details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Harvest.colors(context).ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircularNavButton(
              icon: isSaved ? Icons.favorite : Icons.favorite_border,
              iconColor: isSaved ? Harvest.tomato : Harvest.colors(context).ink,
              onPressed: () {
                store.toggleSaved(p.id);
                HapticFeedback.lightImpact();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: InboxIndicator(
              onOpen: () => openPage(context, const NotificationsScreen()),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 10),

          // 1. 3D Pedestal Showcase Stage matching Reference 1 (Screen 2)
          Center(
            child: SizedBox(
              width: 280,
              height: 250,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glass Pedestal Ellipse Shadow
                  Positioned(
                    bottom: 18,
                    child: Container(
                      width: 220,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.all(
                          Radius.elliptical(220, 48),
                        ),
                        border: Border.all(
                          color: const Color(0xFF10B981)
                              .withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0E4D34)
                                .withValues(alpha: 0.08),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Central Showcase Plant / Produce Photo
                  Positioned(
                    top: 10,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: ClipRRect(
                        key: ValueKey(_selectedThumbnail),
                        borderRadius: BorderRadius.circular(24),
                        child: Photo(
                          thumbnails[_selectedThumbnail],
                          bytes: _selectedThumbnail == 0 ? p.photo : null,
                          width: 190,
                          height: 180,
                          radius: 24,
                          label: p.name,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Show a gallery only when additional farmer-provided photos exist.
          if (thumbnails.length > 1)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(thumbnails.length, (idx) {
                  final isSelected = _selectedThumbnail == idx;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () {
                        setState(() => _selectedThumbnail = idx);
                        HapticFeedback.selectionClick();
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          color: Harvest.colors(context).surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? Harvest.forest
                                : Harvest.colors(context).border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: Harvest.forest.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Photo(
                            thumbnails[idx],
                            width: 50,
                            height: 50,
                            radius: 10,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          const SizedBox(height: 16),

          // 3. Detail Container Sheet matching Reference 1 (Screen 2)
          Container(
            decoration: BoxDecoration(
              color: Harvest.colors(context).surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0A000000),
                  blurRadius: 24,
                  offset: Offset(0, -6),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title & Price Row with Discount Tag matching Image 3 Screen 3
                Text(p.name, style: Harvest.editorial(25)),
                if (offers.length > 1) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey(p.id),
                    initialValue: offers.any((offer) => offer.id == p.id)
                        ? p.id
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Choose farmer',
                    ),
                    items: offers
                        .map(
                          (offer) => DropdownMenuItem(
                            value: offer.id,
                            child: Text(
                              '${store.farm(offer.farmId).name} · ${money(offer.price)}${offer.stock > 0 ? '' : ' · Sold out'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (id) => setState(() {
                      _selectedOfferId = id;
                      _quantity = 1;
                    }),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 10,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          '${money(p.price)} / ${p.unit}',
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16A34A),
                          ),
                        ),
                        Text(
                          'Rs. ${((p.price * 1.25) / 100).toStringAsFixed(0)}',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            decoration: TextDecoration.lineThrough,
                            color: Harvest.colors(context).muted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '20% Off',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFD97706),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Harvest.colors(context).surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: Harvest.colors(context).border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            icon: const Icon(Icons.remove, size: 16),
                            onPressed: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              '$_quantity',
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 30,
                              minHeight: 30,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            onPressed: _quantity < (p.stock > 0 ? p.stock : 1)
                                ? () => setState(() => _quantity++)
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Stock Badge Row
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: p.stock > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p.stock > 0
                          ? 'In Stock · ${p.stock} ${p.unit} available'
                          : 'Out of stock',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: p.stock > 0
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Description
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Harvest.colors(context).ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  p.description.isEmpty
                      ? 'The farmer has not added a description yet.'
                      : p.description,
                  maxLines: _isDescriptionExpanded ? null : 3,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: Harvest.colors(context).muted,
                    height: 1.45,
                  ),
                ),
                InkWell(
                  onTap: () => setState(
                    () => _isDescriptionExpanded = !_isDescriptionExpanded,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      _isDescriptionExpanded ? 'Read Less' : 'Read More',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF16A34A),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 3 Trust Badges Row matching Image 3 Screen 3
                Row(
                  children: [
                    _trustBadge(
                      context,
                      icon: Icons.eco_rounded,
                      label: p.category,
                      color: const Color(0xFF16A34A),
                    ),
                    const SizedBox(width: 8),
                    _trustBadge(
                      context,
                      icon: Icons.science_outlined,
                      label: '${p.stock} in stock',
                      color: const Color(0xFF2563EB),
                    ),
                    const SizedBox(width: 8),
                    _trustBadge(
                      context,
                      icon: Icons.place_outlined,
                      label: 'Per ${p.unit}',
                      color: const Color(0xFFD97706),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Farmer Card with Follow Button matching Image 3 Screen 3
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Harvest.colors(context).canvas,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Harvest.colors(context).border),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Photo(
                          farm.image,
                          width: 48,
                          height: 48,
                          radius: 14,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    farm.name,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                OutlinedButton(
                                  onPressed: () =>
                                      toggleFarmFollow(context, farm),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: const Color(0xFF1E5631),
                                    side: const BorderSide(
                                      color: Color(0xFF1E5631),
                                      width: 1.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(
                                    store.isFollowed(farm.id)
                                        ? 'Following'
                                        : 'Follow',
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  color: Color(0xFFF59E0B),
                                  size: 14,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  'Farm listing',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Harvest.colors(context).muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              farm.location.isEmpty
                                  ? 'Location not published'
                                  : farm.location,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                color: Harvest.colors(context).muted,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2x2 Nutrition Highlights Grid matching Image 3 Screen 3
                Text(
                  'Nutrition Highlights',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Harvest.colors(context).ink,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _nutritionCard(
                        context,
                        title: 'Vitamin C',
                        subtitle: 'Rich in antioxidants',
                        icon: Icons.shield_outlined,
                        color: const Color(0xFF16A34A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _nutritionCard(
                        context,
                        title: 'Vitamin A',
                        subtitle: 'Supports eye health',
                        icon: Icons.visibility_outlined,
                        color: const Color(0xFFEA580C),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _nutritionCard(
                        context,
                        title: 'Lycopene',
                        subtitle: 'Good for heart',
                        icon: Icons.favorite_outline_rounded,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _nutritionCard(
                        context,
                        title: 'Low Calories',
                        subtitle: 'Only 18 kcal/100g',
                        icon: Icons.bolt_rounded,
                        color: const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Related Products Strip
                Text(
                  'Related Products',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Harvest.colors(context).ink,
                  ),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final rel in relatedProducts)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () =>
                                openPage(context, ProductScreen(product: rel)),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Photo(
                                rel.displayImage,
                                bytes: rel.photo,
                                width: 70,
                                height: 70,
                                radius: 16,
                              ),
                            ),
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

      // 4. Sticky Bottom Action Bar matching Reference 1 (Screen 2) "+ Add To Cart"
      bottomNavigationBar: store.role != UserRole.customer
          ? null
          : BottomAction(
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Harvest.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: p.stock == 0
                      ? null
                      : () {
                          if (store.isDemo) {
                            requireGuestSignIn(context, addingToCart: true);
                            return;
                          }
                          final current = store.basket[p.id] ?? 0;
                          final err = store.setQuantity(
                            p.id,
                            current + _quantity,
                          );
                          if (err == null) {
                            HapticFeedback.mediumImpact();
                            notice(
                              context,
                              'Added ${_quantity}x ${p.name} to basket',
                            );
                          } else {
                            notice(context, err, isError: true);
                          }
                        },
                  child: Text(
                    p.stock == 0 ? 'Out of stock' : 'Add to cart',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
