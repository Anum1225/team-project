part of '../customer.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  int _selectedTab = 0; // 0: Products, 1: Farmers
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final query = _search.text.trim().toLowerCase();
    final savedProducts = store.products
        .where((p) => store.saved.contains(p.id))
        .where(
          (p) =>
              query.isEmpty ||
              '${p.name} ${p.category} ${store.farm(p.farmId).name}'
                  .toLowerCase()
                  .contains(query),
        )
        .toList();
    final followedFarms = store.farms
        .where((f) => store.isFollowed(f.id))
        .where(
          (f) =>
              query.isEmpty ||
              '${f.name} ${f.location} ${f.market}'.toLowerCase().contains(
                query,
              ),
        )
        .toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          'My Wishlist',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: store.basketProductCount > 0,
              label: Text(
                '${store.basketProductCount}',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              backgroundColor: const Color(0xFFEF4444),
              child: Icon(Icons.shopping_bag_outlined, size: 22),
            ),
            onPressed: () => openPage(context, const BasketScreen()),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Tab selection pills: Products (6) | Farmers (3)
          Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedTab == 0 ? palette.green : palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedTab == 0 ? palette.green : palette.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    'Products (${savedProducts.length})',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: _selectedTab == 0
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _selectedTab == 0 ? Colors.white : palette.ink,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => setState(() => _selectedTab = 1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _selectedTab == 1 ? palette.green : palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _selectedTab == 1 ? palette.green : palette.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    'Farmers (${followedFarms.length})',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: _selectedTab == 1
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: _selectedTab == 1 ? Colors.white : palette.ink,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          SearchBox(
            controller: _search,
            hint: _selectedTab == 0
                ? 'Search saved products…'
                : 'Search followed farmers…',
            onChanged: (_) => setState(() {}),
            voiceSearch: true,
          ),
          const SizedBox(height: 14),

          if (_selectedTab == 0) ...[
            if (savedProducts.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_border_rounded,
                        size: 48,
                        color: palette.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Your Wishlist is Empty',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tap the heart icon on any produce to save it here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final p in savedProducts) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.03,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Photo with red heart badge
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Photo(
                              p.displayImage,
                              bytes: p.photo,
                              width: 72,
                              height: 72,
                              radius: 16,
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: GestureDetector(
                              onTap: () {
                                store.toggleSaved(p.id);
                                HapticFeedback.lightImpact();
                              },
                              child: Container(
                                width: 22,
                                height: 22,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.favorite_rounded,
                                  size: 13,
                                  color: Color(0xFFEF4444),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 14),

                      // Produce Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.name,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${money(p.price)} / ${p.unit}',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                                color: palette.green,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              store.farm(p.farmId).name,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: palette.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Add to Cart Button
                      FilledButton(
                        onPressed: () {
                          if (store.isDemo) {
                            requireGuestSignIn(context, addingToCart: true);
                            return;
                          }
                          final error = store.setQuantity(
                            p.id,
                            (store.basket[p.id] ?? 0) + 1,
                          );
                          if (error == null) HapticFeedback.mediumImpact();
                          notice(
                            context,
                            error ?? 'Added ${p.name} to basket',
                            isError: error != null,
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Add to cart',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ] else ...[
            if (followedFarms.isEmpty)
              Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.storefront_outlined,
                        size: 48,
                        color: palette.muted,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No Followed Farmers',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: palette.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Follow local growers to see them here and get restock updates.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: palette.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              for (final f in followedFarms) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: palette.border, width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: isDark ? 0.20 : 0.03,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Photo(
                          f.image,
                          width: 58,
                          height: 58,
                          radius: 16,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              f.name,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              f.location,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 11,
                                color: palette.muted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.storefront_outlined,
                                  size: 14,
                                  color: Color(0xFFF59E0B),
                                ),
                                const SizedBox(width: 3),
                                const Text(
                                  'View farm',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton(
                        onPressed: () => openPage(context, FarmScreen(farm: f)),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: palette.green),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'View',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: palette.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
          ],
        ],
      ),
    );
  }
}
