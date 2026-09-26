import 'notifications.dart';
import 'dart:async';
import 'assistant_robot.dart';
import 'location_picker.dart';
import 'package:geolocator/geolocator.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components.dart';
import 'models.dart';
import 'orders.dart';
import 'profile.dart';
import 'store.dart';
import 'theme.dart';

class BasketAction extends StatelessWidget {
  const BasketAction({super.key, this.floating = false});
  final bool floating;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.role != UserRole.customer) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Your basket',
      style: floating
          ? IconButton.styleFrom(
              fixedSize: const Size(82, 82),
              backgroundColor: Harvest.colors(context).forest,
              foregroundColor: Colors.white,
              elevation: 8,
              shadowColor: const Color(0x55305236),
            )
          : null,
      onPressed: () => openPage(context, const BasketScreen()),
      icon: Badge(
        isLabelVisible: store.basketCount > 0,
        label: Text(
          '${store.basketCount}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Harvest.forest,
        child: Icon(Icons.shopping_bag_outlined, size: floating ? 32 : 22),
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onExplore,
    required this.onAssistant,
    required this.onProfile,
  });

  final VoidCallback onExplore, onAssistant, onProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final categories = ['All', ...store.categories];
    final available = store.products
        .where(
          (product) => product.stock > 0 && store.farm(product.farmId).active,
        )
        .toList();
    final products =
        (_category == 'All'
              ? available
              : available
                    .where((product) => product.category == _category)
                    .toList())
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final address = store.account.address.trim();
    final featuredFarms = store.farms.where((f) => f.active).take(4).toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 30),
            children: [
              HarvestHubBrandHeader(
                marketName: address.isEmpty
                    ? 'Fresh from local farms'
                    : address,
                unreadNotifications: false,
                onLocationTap: () =>
                    openPage(context, const ProfileEditorScreen()),
                onNotificationTap: () =>
                    openPage(context, const NotificationsScreen()),
                onProfileTap: widget.onProfile,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good food, ${store.account.name.split(' ').first}.',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Picked and listed by growers in your HarvestHub market.',
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SearchBox(
                  hint: 'Search produce, growers, or markets…',
                  readOnly: true,
                  onTap: widget.onExplore,
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _marketplaceHero(
                  context,
                  onExplore: widget.onExplore,
                  onAssistant: widget.onAssistant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Browse categories',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExplore,
                      child: const Text('All products'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                      selectedColor: palette.green,
                      labelStyle: TextStyle(
                        color: category == _category
                            ? Colors.white
                            : palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: category == _category
                            ? palette.green
                            : palette.border,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _category == 'All' ? 'Available now' : _category,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExplore,
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: InfoNote(
                    store.loading
                        ? 'Loading products from your market…'
                        : _category == 'All'
                        ? 'No in-stock products are listed in your market yet.'
                        : 'No in-stock products in this category yet.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ProductGrid(
                    products: products.take(4).toList(),
                    onOpen: (product) =>
                        openPage(context, ProductScreen(product: product)),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Meet the growers',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          openPage(context, const AllFarmsScreen()),
                      child: const Text('Directory'),
                    ),
                  ],
                ),
              ),
              if (featuredFarms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: InfoNote(
                    'Farmer profiles will appear here as local growers join.',
                  ),
                )
              else
                ...featuredFarms.map((farm) {
                  final stockCount = store.products
                      .where((p) => p.farmId == farm.id && p.stock > 0)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
                    child: Material(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: palette.paleLeaf,
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: palette.green,
                          ),
                        ),
                        title: Text(
                          farm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${farm.location.isEmpty ? farm.market : farm.location} · $stockCount products',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: palette.muted,
                        ),
                        onTap: () => openPage(context, FarmScreen(farm: farm)),
                      ),
                    ),
                  );
                }),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                child: _assistantInvite(
                  context,
                  palette,
                  onTap: widget.onAssistant,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            AssistantRobot(onTap: widget.onAssistant),
            const BasketAction(floating: true),
          ],
        ),
      ),
    );
  }

  Widget _marketplaceHero(
    BuildContext context, {
    required VoidCallback onExplore,
    required VoidCallback onAssistant,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143E2B), Color(0xFF246A43), Color(0xFF37794D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22244531),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FROM GROWER TO TABLE',
                  style: TextStyle(
                    color: Color(0xFFCDEBCF),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fresh from farms\nnear your home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _heroAction(
                      'Shop produce',
                      Icons.arrow_forward_rounded,
                      onExplore,
                    ),
                    _heroAction(
                      'Ask the assistant',
                      Icons.auto_awesome_rounded,
                      onAssistant,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.eco_rounded, color: Color(0xFFB7E4B8), size: 48),
        ],
      ),
    );
  }

  Widget _heroAction(String label, IconData icon, VoidCallback onTap) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 15),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: .5)),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          visualDensity: VisualDensity.compact,
        ),
      );

  Widget _assistantInvite(
    BuildContext context,
    HarvestPalette palette, {
    required VoidCallback onTap,
  }) => Material(
    color: palette.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.paleLeaf,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: palette.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HarvestHub assistant',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ask about produce, storage, and nutrition.',
                    style: TextStyle(color: palette.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: palette.green, size: 18),
          ],
        ),
      ),
    ),
  );
}

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key, this.initialCategory});
  final String? initialCategory;

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _search = TextEditingController();
  late String _category = widget.initialCategory ?? 'All';
  String? _selectedFarmId;
  bool _onlyInStock = true;
  String _sort = 'Name';
  double? _latitude, _longitude, _radius;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _showFilters(HarvestStore store) async {
    var stockOnly = _onlyInStock;
    var farmId = _selectedFarmId;
    var sort = _sort;
    var latitude = _latitude, longitude = _longitude, radius = _radius;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SheetBody(
          children: [
            const PageHeading(
              'Refine your search',
              subtitle: 'Filter the live farm catalog.',
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: stockOnly,
              title: const Text('Available stock only'),
              subtitle: const Text(
                'Hide products that are currently sold out.',
              ),
              onChanged: (value) => update(() => stockOnly = value),
            ),
            const SectionHeader('Farm'),
            Wrap(
              spacing: 8,
              runSpacing: 7,
              children: [
                ChoiceChip(
                  label: const Text('All farms'),
                  selected: farmId == null,
                  onSelected: (_) => update(() => farmId = null),
                ),
                for (final farm in store.farms)
                  ChoiceChip(
                    label: Text(farm.name),
                    selected: farmId == farm.id,
                    onSelected: (_) => update(() => farmId = farm.id),
                  ),
              ],
            ),
            const SectionHeader('Distance from location'),
            Row(
              children: [
                Expanded(
                  child: Text(
                    latitude == null
                        ? 'Choose a map point or use autodetect.'
                        : 'Location selected · distances use farm coordinates.',
                  ),
                ),
                LocationPickerButton(
                  onSelected: (value) {
                    final parts = value.split(',');
                    update(() {
                      latitude = double.tryParse(parts.first.trim());
                      longitude = double.tryParse(parts.last.trim());
                    });
                  },
                ),
              ],
            ),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Any distance'),
                  selected: radius == null,
                  onSelected: (_) => update(() => radius = null),
                ),
                for (final km in [5.0, 10.0, 25.0, 50.0])
                  ChoiceChip(
                    label: Text('${km.toInt()} km'),
                    selected: radius == km,
                    onSelected: latitude == null
                        ? null
                        : (_) => update(() => radius = km),
                  ),
              ],
            ),
            const SectionHeader('Sort by'),
            ChoiceRow(
              values: const [
                'Name',
                'Price: low to high',
                'Price: high to low',
              ],
              selected: sort,
              onSelected: (value) => update(() => sort = value),
            ),
            const SizedBox(height: 12),
            HarvestButton(
              label: 'Apply filters',
              onPressed: () {
                setState(() {
                  _onlyInStock = stockOnly;
                  _selectedFarmId = farmId;
                  _sort = sort;
                  _latitude = latitude;
                  _longitude = longitude;
                  _radius = radius;
                });
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final query = _search.text.trim().toLowerCase();
    final products = store.products.where((product) {
      if (_category != 'All' && product.category != _category) return false;
      if (_selectedFarmId != null && product.farmId != _selectedFarmId) {
        return false;
      }
      if (_onlyInStock && product.stock <= 0) return false;
      final farm = store.farm(product.farmId);
      if (!farm.active) return false;
      if (_radius != null && _latitude != null && _longitude != null) {
        if (farm.latitude == null || farm.longitude == null) return false;
        if (Geolocator.distanceBetween(
              _latitude!,
              _longitude!,
              farm.latitude!,
              farm.longitude!,
            ) >
            _radius! * 1000) {
          return false;
        }
      }
      if (query.isNotEmpty &&
          !'${product.name} ${product.category} ${farm.name} ${farm.market} ${farm.location}'
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      return true;
    }).toList();
    products.sort(
      (a, b) => switch (_sort) {
        'Price: low to high' => a.price.compareTo(b.price),
        'Price: high to low' => b.price.compareTo(a.price),
        _ => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      },
    );
    final categories = ['All', ...store.categories];

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Explore produce'),
        actions: [const BasketAction(), const SizedBox(width: 8)],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 7, 18, 10),
            child: Row(
              children: [
                Expanded(
                  child: SearchBox(
                    controller: _search,
                    hint: 'Search produce, farms, markets…',
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (value) => store.rememberSearch(value),
                    voiceSearch: true,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Filter and sort products',
                  onPressed: () => _showFilters(store),
                  icon: const Icon(Icons.tune_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: palette.paleLeaf,
                    foregroundColor: palette.green,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = categories[index];
                final active = category == _category;
                return ChoiceChip(
                  label: Text(category),
                  selected: active,
                  onSelected: (_) => setState(() => _category = category),
                  selectedColor: palette.green,
                  labelStyle: TextStyle(
                    color: active ? Colors.white : palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                  side: BorderSide(
                    color: active ? palette.green : palette.border,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${products.length} ${products.length == 1 ? 'product' : 'products'}',
                    style: TextStyle(
                      color: palette.muted,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (_selectedFarmId != null || !_onlyInStock || _sort != 'Name')
                  TextButton(
                    onPressed: () => setState(() {
                      _selectedFarmId = null;
                      _onlyInStock = true;
                      _sort = 'Name';
                    }),
                    child: const Text('Reset filters'),
                  ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: InfoNote(
                        store.loading
                            ? 'Loading live farm listings…'
                            : query.isEmpty
                            ? 'No products match these filters.'
                            : 'No products match your search.',
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      final columns = constraints.maxWidth > 700 ? 3 : 2;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: constraints.maxWidth > 700
                              ? .72
                              : .62,
                        ),
                        itemBuilder: (context, index) => ProductCard(
                          product: products[index],
                          onOpen: () {
                            store.rememberSearch(query);
                            openPage(
                              context,
                              ProductScreen(product: products[index]),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

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
        widget.product ??
        (widget.productId != null ? store.product(widget.productId!) : null);
    if (p == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Details')),
        body: const Center(child: Text('Product not found')),
      );
    }
    final farm = store.farm(p.farmId);
    final isSaved = store.saved.contains(p.id);
    final relatedProducts = store.visibleProducts
        .where((item) => item.id != p.id)
        .take(4)
        .toList();

    final thumbnails = [
      p.image,
      'farm',
      'tomatoes',
      'strawberries',
      'potatoes',
    ];

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
          'Farm Details',
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
            child: CircularNavButton(
              icon: Icons.notifications_none_outlined,
              hasBadge: true,
              onPressed: () =>
                  notice(context, 'Farm notification: Harvested this morning!'),
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
                          color: const Color(
                            0xFF10B981,
                          ).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xFF0E4D34,
                            ).withValues(alpha: 0.08),
                            blurRadius: 18,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Pedestal Rotate Pill < - >
                  Positioned(
                    bottom: 34,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Harvest.forest,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x20000000),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_left, color: Colors.white, size: 14),
                          Icon(
                            Icons.sync_rounded,
                            color: Colors.white,
                            size: 11,
                          ),
                          Icon(
                            Icons.arrow_right,
                            color: Colors.white,
                            size: 14,
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

          // 2. 5-item Thumbnail Strip matching Reference 1 (Screen 2)
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
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Following ${farm.name}!',
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  },
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
                                  child: const Text(
                                    'Follow',
                                    style: TextStyle(
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
                                rel.image,
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
                child: FilledButton.icon(
                  icon: const Icon(Icons.add, size: 20, color: Colors.white),
                  label: Text(
                    p.stock == 0 ? 'Out of stock' : 'Add to basket',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: Harvest.forest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: p.stock == 0
                      ? null
                      : () {
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
                ),
              ),
            ),
    );
  }
}

class FarmerTile extends StatelessWidget {
  const FarmerTile({super.key, required this.farm});
  final Farm farm;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Harvest.colors(context).surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Harvest.colors(context).border),
    ),
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Photo(farm.image, width: 44, height: 44, radius: 12),
        title: Text(
          farm.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${farm.location} · ${farm.market}',
          style: TextStyle(fontSize: 12, color: Harvest.colors(context).muted),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: Harvest.colors(context).muted,
        ),
        onTap: () => openPage(context, FarmScreen(farm: farm)),
      ),
    ),
  );
}

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, this.farm, this.farmId});
  final Farm? farm;
  final String? farmId;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final f = farm ?? (farmId != null ? store.farm(farmId!) : null);
    if (f == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Profile')),
        body: const Center(child: Text('Farm not found')),
      );
    }
    final products = store.products.where((p) => p.farmId == f.id).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  store.isFollowed(f.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: store.isFollowed(f.id)
                      ? const Color(0xFFEF4444)
                      : Colors.white,
                ),
                tooltip: store.isFollowed(f.id)
                    ? 'Unfollow Farm'
                    : 'Follow Farm & Get Restock Alerts',
                onPressed: () {
                  store.toggleFollowed(f.id);
                  notice(
                    context,
                    store.isFollowed(f.id)
                        ? 'Following ${f.name}! Restock alerts activated.'
                        : 'Unfollowed ${f.name}.',
                  );
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Photo(f.image, radius: 0, width: double.infinity),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Eyebrow(f.market)),
                      TextButton.icon(
                        onPressed: () {
                          store.toggleFollowed(f.id);
                          notice(
                            context,
                            store.isFollowed(f.id)
                                ? 'Following ${f.name}! Restock alerts activated.'
                                : 'Unfollowed ${f.name}.',
                          );
                        },
                        style: TextButton.styleFrom(
                          backgroundColor: store.isFollowed(f.id)
                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                              : Harvest.colors(context).surface,
                          foregroundColor: store.isFollowed(f.id)
                              ? const Color(0xFF16A34A)
                              : Harvest.colors(context).ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: store.isFollowed(f.id)
                                  ? const Color(0xFF16A34A)
                                  : Harvest.colors(context).border,
                            ),
                          ),
                        ),
                        icon: Icon(
                          store.isFollowed(f.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: store.isFollowed(f.id)
                              ? const Color(0xFFEF4444)
                              : Harvest.colors(context).muted,
                        ),
                        label: Text(
                          store.isFollowed(f.id) ? 'Following' : 'Follow Farm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(f.name, style: Harvest.editorial(32)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Harvest.colors(context).muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          f.location,
                          style: TextStyle(
                            color: Harvest.colors(context).muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (store.isFollowed(f.id)) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(
                            0xFF16A34A,
                          ).withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Personalized restock alerts enabled for this farm.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    f.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Harvest.colors(context).ink,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionHeader('Harvests Available (${products.length})'),
                  ProductGrid(
                    products: products,
                    onOpen: (p) => openPage(context, ProductScreen(product: p)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
              isLabelVisible: store.basketCount > 0,
              label: Text(
                '${store.basketCount}',
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
                              p.image,
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
                      FilledButton.icon(
                        onPressed: () {
                          store.setQuantity(
                            p.id,
                            (store.basket[p.id] ?? 0) + 1,
                          );
                          HapticFeedback.mediumImpact();
                          notice(context, 'Added ${p.name} to basket');
                        },
                        icon: const Icon(
                          Icons.add_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'Add',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
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

class BasketScreen extends StatelessWidget {
  const BasketScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = store.basket.entries.map((e) {
      final p = store.product(e.key)!;
      return (p, e.value);
    }).toList();

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
              message:
                  'Browse our local growers to discover fruits, vegetables, and pantry items harvested fresh today.',
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
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Photo(
                            p.image,
                            bytes: p.photo,
                            width: 68,
                            height: 68,
                            radius: 14,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14.5,
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
                  onPressed: () => openPage(context, const CheckoutScreen()),
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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _address = TextEditingController();
  String? _selectedPickupSlot;
  bool _busy = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final store = HarvestScope.of(context);
      _address.text = store.account.address;
    }
  }

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final store = HarvestScope.of(context);
    if (_address.text.trim().isEmpty) {
      notice(context, 'Please enter a contact address', isError: true);
      return;
    }

    setState(() => _busy = true);
    if (!mounted) return;
    try {
      final created = await store.checkout(
        _address.text.trim(),
        pickupSlot: _selectedPickupSlot,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmationScreen(orders: created)),
      );
    } catch (e) {
      notice(context, e.toString(), isError: true);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);

    final basketFarms = store.basket.keys
        .map((id) => store.farm(store.product(id)!.farmId))
        .toList();
    final timeSlots = basketFarms.isEmpty
        ? <String>[]
        : basketFarms.first.pickupSlots
              .where(
                (slot) => basketFarms.every(
                  (farm) => farm.pickupSlots.contains(slot),
                ),
              )
              .toList();
    if (!timeSlots.contains(_selectedPickupSlot)) _selectedPickupSlot = null;

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
          'Checkout',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
        children: [
          // Step 1: Customer contact address
          _stepHeader(
            1,
            'Order contact address',
            trailing: 'Change',
            onTrailingTap: () {
              // Edit address dialog
              showDialog<void>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text(
                    'Edit Contact Address',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  content: TextField(controller: _address, maxLines: 3),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Done'),
                    ),
                  ],
                ),
              );
            },
            palette: palette,
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border, width: 1.2),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF10B981),
                  size: 22,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        store.account.name,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _address.text,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          color: palette.muted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      if (store.account.phone.isNotEmpty)
                        Text(
                          store.account.phone,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            color: palette.muted,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Step 2: Pickup is recorded as a customer-requested time window.
          _stepHeader(2, 'Farm pickup', palette: palette),
          const SizedBox(height: 10),
          const InfoNote(
            'Choose a farmer-published window, or book later from Orders. Only times offered by every farm in this basket appear here.',
          ),
          const SizedBox(height: 20),

          // Step 3: Pickup time request
          _stepHeader(3, 'Available pickup windows', palette: palette),
          if (timeSlots.isEmpty)
            const InfoNote(
              'No shared pickup windows published. Place your order and arrange pickup with each farm.',
            ),
          TextButton(
            onPressed: () => setState(() => _selectedPickupSlot = null),
            child: const Text('Arrange pickup later'),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.8,
            children: timeSlots.map((slot) {
              final sel = _selectedPickupSlot == slot;
              return GestureDetector(
                onTap: () => setState(() => _selectedPickupSlot = slot),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: sel ? palette.green : palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? palette.green : palette.border,
                      width: 1.2,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    slot,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                      color: sel ? Colors.white : palette.ink,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const InfoNote('This is a simulated order. No payment is collected.'),
          const SizedBox(height: 16),

          // Confirmed totals are based on the live basket.
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: palette.border, width: 1.2),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order Summary',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${store.basketCount} items',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: palette.muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  money(store.basketTotal),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: palette.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: 'Place simulated order · ${money(store.basketTotal)}',
          busy: _busy,
          onPressed: _busy ? null : _confirm,
        ),
      ),
    );
  }

  Widget _stepHeader(
    int stepNum,
    String title, {
    String? trailing,
    VoidCallback? onTrailingTap,
    required HarvestPalette palette,
  }) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: const BoxDecoration(
            color: Color(0xFF10B981),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            '$stepNum',
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: palette.ink,
            ),
          ),
        ),
        if (trailing != null)
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailing,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2563EB),
              ),
            ),
          ),
      ],
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.orders});
  final List<HarvestOrder> orders;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Harvest.colors(context).cream,
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Spacer(),
            Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Harvest.colors(context).paleLeaf,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Harvest.colors(context).green,
              ),
            ),
            const SizedBox(height: 24),
            Text('Order confirmed', style: Harvest.editorial(32)),
            const SizedBox(height: 10),
            Text(
              'Your order ${orders.map((o) => o.id).join(', ')} has been placed directly with the growers.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Harvest.colors(context).muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Harvest.colors(context).surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Harvest.colors(context).border),
              ),
              child: Column(
                children: [
                  for (final o in orders)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            o.farmName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          money(o.total),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Harvest.colors(context).green,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const Spacer(),
            HarvestButton(
              label: 'View Order Status',
              onPressed: () {
                Navigator.pop(context);
                openPage(context, const OrdersScreen());
              },
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Today's Weather & Crop Notes Screen matching Reference Image 1 (Screen 3)
class AllFarmsScreen extends StatefulWidget {
  const AllFarmsScreen({super.key, this.followedOnly = false});
  final bool followedOnly;

  @override
  State<AllFarmsScreen> createState() => _AllFarmsScreenState();
}

class _AllFarmsScreenState extends State<AllFarmsScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final query = _search.text.trim().toLowerCase();
    final farms =
        store.farms.where((farm) {
          if (!farm.active) return false;
          if (widget.followedOnly && !store.followed.contains(farm.id)) {
            return false;
          }
          if (query.isEmpty) return true;
          return '${farm.name} ${farm.location} ${farm.market} ${farm.description}'
              .toLowerCase()
              .contains(query);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: Text(
          widget.followedOnly ? 'Followed farmers' : 'Farmers & farms',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: SearchBox(
              controller: _search,
              hint: 'Search farmer, farm or market…',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: farms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: InfoNote(
                        widget.followedOnly
                            ? 'You are not following any farmers yet.'
                            : query.isEmpty
                            ? 'No farms are available yet.'
                            : 'No farms match that search.',
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    itemCount: farms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final farm = farms[i];
                      final products = store.products
                          .where((p) => p.farmId == farm.id && p.stock > 0)
                          .length;
                      final following = store.isFollowed(farm.id);
                      return Material(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              openPage(context, FarmScreen(farm: farm)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(17),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFD8F1DE),
                                        Color(0xFFB8DFC1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.agriculture_rounded,
                                    color: palette.forest,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        farm.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.ink,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [farm.location, farm.market]
                                            .where((s) => s.trim().isNotEmpty)
                                            .join(' · ')
                                            .ifEmpty('Local farm'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '$products products available',
                                        style: TextStyle(
                                          color: palette.green,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: following
                                      ? 'Unfollow farmer'
                                      : 'Follow farmer',
                                  onPressed: () => setState(
                                    () => store.toggleFollowed(farm.id),
                                  ),
                                  icon: Icon(
                                    following
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: following
                                        ? const Color(0xFFE15D53)
                                        : palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
