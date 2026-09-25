import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'components.dart';
import 'models.dart';
import 'orders.dart';
import 'store.dart';
import 'theme.dart';

class BasketAction extends StatelessWidget {
  const BasketAction({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.role != UserRole.customer) return const SizedBox.shrink();

    return IconButton(
      tooltip: 'Your basket',
      onPressed: () => openPage(context, const BasketScreen()),
      icon: Badge(
        isLabelVisible: store.basketCount > 0,
        label: Text(
          '${store.basketCount}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800),
        ),
        backgroundColor: Harvest.forest,
        child: const Icon(Icons.shopping_bag_outlined, size: 22),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.onExplore,
    required this.onAssistant,
    required this.onProfile,
  });

  final VoidCallback onExplore, onAssistant, onProfile;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final name = store.account.name.split(' ').first;
    final featuredProducts = store.visibleProducts.take(4).toList();
    final farms = store.farms;
    final recentOrders = store.visibleOrders.take(1).toList();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // 1. Deep Emerald Top Section matching Reference Image 1 (Screen 1)
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          decoration: const BoxDecoration(
            gradient: Harvest.forestGradient,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Action Bar Row
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Text(
                              'Hello, ',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              'Good Morning',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            openPage(context, const TodaysWeatherScreen());
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Sunday, 01 Dec 2024',
                                  style: TextStyle(
                                    color: Color(0xFFD1E7DD),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Icon(
                                  Icons.keyboard_arrow_down,
                                  color: Color(0xFFD1E7DD),
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Saved items',
                    onPressed: () => openPage(context, const WishlistScreen()),
                    icon: Badge(
                      isLabelVisible: store.saved.isNotEmpty,
                      backgroundColor: Harvest.tomato,
                      smallSize: 8,
                      child: const Icon(
                        Icons.favorite_border,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Your basket',
                    onPressed: () => openPage(context, const BasketScreen()),
                    icon: Badge(
                      isLabelVisible: store.basketCount > 0,
                      label: Text(
                        '${store.basketCount}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      backgroundColor: Harvest.honey,
                      textColor: Harvest.darkSoil,
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  // User Avatar Circle
                  Material(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onProfile,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.5),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          name.isEmpty ? 'H' : name[0],
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Translucent Search Bar with Mic Icon
              Material(
                color: Colors.white.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: onExplore,
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.search, color: Colors.white70, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Search here...',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.mic_none_rounded,
                          color: Colors.white70,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 2. Overlapping Weather & Climate Card matching Reference 1 (Screen 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: WeatherClimateCard(
            location: 'Chateauneuf-du-Pape',
            temperature: '+17°C',
            highLow: 'H: 23°C   L: 14°C',
            humidity: '40%',
            precipitation: '5.1ml',
            pressure: '450 hpa',
            wind: '23m/s',
            sunrise: '5:25 am',
            sunset: '8:04 am',
            onTap: () => openPage(context, const TodaysWeatherScreen()),
          ),
        ),

        // 3. Invest by Category matching Reference 1 (Screen 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader('Invest by Category'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: InvestCategoryCard(
                      title: 'Duration',
                      icon: Icons.hourglass_bottom_rounded,
                      iconColor: const Color(0xFF2563EB),
                      iconBg: const Color(0xFFEBF3FE),
                      onTap: () => openPage(context, const AllFarmsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InvestCategoryCard(
                      title: 'Return',
                      icon: Icons.trending_up_rounded,
                      iconColor: const Color(0xFF10B981),
                      iconBg: const Color(0xFFE8F8F0),
                      onTap: () => openPage(context, const AllFarmsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InvestCategoryCard(
                      title: 'Low Risk',
                      icon: Icons.balance_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      iconBg: const Color(0xFFFEF3E8),
                      onTap: () => openPage(context, const AllFarmsScreen()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: InvestCategoryCard(
                      title: 'Safety',
                      icon: Icons.security_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      iconBg: const Color(0xFFE6F7F8),
                      onTap: () => openPage(context, const AllFarmsScreen()),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 4. Best Offers matching Reference 1 (Screen 1)
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: SectionHeader(
            'Best Offers',
            action: 'View all',
            onAction: onExplore,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _BestOfferCard(
                photo: 'farm',
                title: 'Bekasi Timur Paddy',
                tag: '5.5% Earnings',
                price: '10,000 BDT/share',
                onTap: () => openPage(context, const AllFarmsScreen()),
              ),
              const SizedBox(width: 14),
              _BestOfferCard(
                photo: 'market',
                title: 'Chateauneuf Vineyard',
                tag: '6.2% Return',
                price: '15,000 BDT/share',
                onTap: () => openPage(context, const AllFarmsScreen()),
              ),
              const SizedBox(width: 14),
              _BestOfferCard(
                photo: 'strawberries',
                title: 'Spring Serenade Berry Plot',
                tag: '7.0% Yield',
                price: '8,500 BDT/share',
                onTap: () => openPage(context, const PlantingScreen()),
              ),
            ],
          ),
        ),

        // 5. In Season Categories Capsule Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: SectionHeader(
            'What’s in season?',
            action: 'All categories',
            onAction: onExplore,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final cat in [
                ('Vegetables', 'tomatoes', 'Crisp & leafy'),
                ('Fruits', 'strawberries', 'Sweet harvest'),
                ('Grains', 'potatoes', 'Milled & rooted'),
                ('Pantry', 'honey', 'Wild honey & oils'),
                ('Dairy', 'farm', 'Artisanal farm dairy'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      openPage(context, ExploreScreen(initialCategory: cat.$1));
                    },
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Harvest.border),
                        boxShadow: Harvest.cardShadow,
                      ),
                      child: Column(
                        children: [
                          Photo(cat.$2, height: 64, width: 90, radius: 12),
                          const SizedBox(height: 8),
                          Text(
                            cat.$1,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            cat.$3,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Harvest.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // 6. Seasonal Fresh Today Produce Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: SectionHeader(
            'Fresh Today',
            action: 'Browse all',
            onAction: onExplore,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: ProductGrid(
            products: featuredProducts,
            onOpen: (p) => openPage(context, ProductScreen(product: p)),
          ),
        ),

        // 7. Meet Your Growers Spotlight
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: const SectionHeader(
            'Meet Your Growers',
            subtitle: null,
            icon: Icons.storefront_outlined,
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              for (final f in farms)
                FarmerCard(
                  farm: f,
                  onTap: () => openPage(context, FarmScreen(farm: f)),
                ),
            ],
          ),
        ),

        // 8. Live Crop Advisory & Field Notes Shortcut
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: () => openPage(context, const TodaysWeatherScreen()),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Harvest.forest,
                borderRadius: BorderRadius.circular(22),
                boxShadow: Harvest.ambientShadow,
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.wb_sunny_outlined,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Today’s Farm Weather & Field Notes',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Bekasi Timur: 33°C Cloudy · Pesticides recommended',
                          style: TextStyle(
                            color: Color(0xFFD4E3D7),
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.white70,
                    size: 14,
                  ),
                ],
              ),
            ),
          ),
        ),

        // 9. Interactive AI Assistant Teaser Card
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Harvest.softSage, width: 1.2),
              boxShadow: Harvest.ambientShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Harvest.forest, Harvest.green],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Harvest.green.withValues(alpha: 0.35),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Harvest.honey,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ask Harvest AI',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        '“How should I store fresh vine tomatoes?”',
                        style: TextStyle(
                          color: Harvest.muted,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Open assistant',
                  style: IconButton.styleFrom(backgroundColor: Harvest.sage),
                  onPressed: onAssistant,
                  icon: const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: Harvest.forest,
                  ),
                ),
              ],
            ),
          ),
        ),

        // 10. Recent Order Quick Track
        if (recentOrders.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: SectionHeader(
              'Recent Order',
              action: 'All orders',
              onAction: () => openPage(context, const OrdersScreen()),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: OrderCard(
              order: recentOrders.first,
              onOpen: () => openPage(
                context,
                OrderDetailScreen(order: recentOrders.first),
              ),
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}

class _BestOfferCard extends StatelessWidget {
  const _BestOfferCard({
    required this.photo,
    required this.title,
    required this.tag,
    required this.price,
    required this.onTap,
  });

  final String photo, title, tag, price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(20),
    onTap: onTap,
    child: Container(
      width: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Harvest.border),
        boxShadow: Harvest.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Photo(photo, height: 110, width: 220, radius: 0),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Harvest.forest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Harvest.forest,
                  ),
                ),
              ],
            ),
          ),
        ],
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
  bool _onlyInStock = false;
  int _exploreMode = 0; // 0: Produce Market, 1: Active Farms, 2: Planting

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showFilterSheet() {
    final store = HarvestScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SheetBody(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filters & Sorting',
                    style: Harvest.editorial(24),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setSheetState(() {
                      _category = 'All';
                      _selectedFarmId = null;
                      _onlyInStock = false;
                    });
                    setState(() {});
                  },
                  child: const Text('Reset', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Categories',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['All', ...store.categories].map((c) {
                final sel = _category == c;
                return ChoiceChip(
                  label: Text(c),
                  selected: sel,
                  selectedColor: Harvest.forest,
                  labelStyle: TextStyle(
                    color: sel ? Colors.white : Harvest.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    setSheetState(() => _category = c);
                    setState(() {});
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text(
              'Local Farms',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('All Farms'),
                  selected: _selectedFarmId == null,
                  selectedColor: Harvest.forest,
                  labelStyle: TextStyle(
                    color: _selectedFarmId == null ? Colors.white : Harvest.ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  onSelected: (_) {
                    setSheetState(() => _selectedFarmId = null);
                    setState(() {});
                  },
                ),
                ...store.farms.map((f) {
                  final sel = _selectedFarmId == f.id;
                  return ChoiceChip(
                    label: Text(f.name),
                    selected: sel,
                    selectedColor: Harvest.forest,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Harvest.ink,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setSheetState(() => _selectedFarmId = f.id);
                      setState(() {});
                    },
                  );
                }),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Only available in stock',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: const Text(
                'Hide sold-out items',
                style: TextStyle(fontSize: 12, color: Harvest.muted),
              ),
              value: _onlyInStock,
              activeTrackColor: Harvest.forest,
              onChanged: (val) {
                setSheetState(() => _onlyInStock = val);
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            HarvestButton(
              label: 'Apply Filters',
              onPressed: () => Navigator.pop(sheetContext),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final query = _search.text.trim().toLowerCase();

    final filtered = store.visibleProducts.where((p) {
      if (_category != 'All' && p.category != _category) return false;
      if (_selectedFarmId != null && p.farmId != _selectedFarmId) return false;
      if (_onlyInStock && p.stock <= 0) return false;
      if (query.isNotEmpty) {
        final farm = store.farm(p.farmId);
        final match =
            p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query) ||
            farm.name.toLowerCase().contains(query) ||
            farm.location.toLowerCase().contains(query);
        if (!match) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Explore Produce',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Harvest.ink,
          ),
        ),
        actions: const [BasketAction()],
      ),
      body: Column(
        children: [
          // Directory Mode Switcher [Produce | Active Farms | Planting]
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: Harvest.border),
              ),
              child: Row(
                children: [
                  _modeButton('Produce', 0),
                  _modeButton('Active Farms', 1),
                  _modeButton('Planting', 2),
                ],
              ),
            ),
          ),

          // Main View Switcher
          Expanded(
            child: _exploreMode == 0
                ? _buildMarketProduceView(filtered, store)
                : _exploreMode == 1
                ? _buildActiveFarmsView()
                : _buildPlantingView(),
          ),
        ],
      ),
    );
  }

  Widget _modeButton(String label, int index) {
    final isSelected = _exploreMode == index;
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          setState(() => _exploreMode = index);
          HapticFeedback.selectionClick();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Harvest.forest : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: isSelected ? Colors.white : Harvest.muted,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveFarmsView() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Active Farms',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Harvest.ink,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              size: 18,
              color: Harvest.forest,
            ),
            onPressed: () => openPage(context, const AllFarmsScreen()),
          ),
        ],
      ),
      const SizedBox(height: 10),
      FarmDirectoryCard(
        name: 'Cucumber Farm 13',
        earnings: '5.5%',
        price: '10,000 BDT/share',
        period: '4 Months',
        photo: 'farm',
        onTap: () => notice(context, 'Booking shares for Cucumber Farm 13'),
      ),
      FarmDirectoryCard(
        name: 'Agriculture Farm 27',
        earnings: '5.5%',
        price: '10,000 BDT/share',
        period: '4 Months',
        photo: 'market',
        onTap: () => notice(context, 'Booking shares for Agriculture Farm 27'),
      ),
      FarmDirectoryCard(
        name: 'Korolla Farm 18',
        earnings: '5.5%',
        price: '10,000 BDT/share',
        period: '4 Months',
        photo: 'strawberries',
        onTap: () => notice(context, 'Booking shares for Korolla Farm 18'),
      ),
      FarmDirectoryCard(
        name: 'Enrichment Farm 7',
        earnings: '5.5%',
        price: '10,000 BDT/share',
        period: '4 Months',
        photo: 'potatoes',
        onTap: () => notice(context, 'Booking shares for Enrichment Farm 7'),
      ),
    ],
  );

  Widget _buildPlantingView() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Planting Stories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Harvest.ink,
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.open_in_new,
              size: 18,
              color: Harvest.forest,
            ),
            onPressed: () => openPage(context, const PlantingScreen()),
          ),
        ],
      ),
      const SizedBox(height: 10),
      _plantingCard(
        'Spring Serenade Farming',
        'Robert Fox',
        'New York, USA',
        '\$22.00-400.00',
        'farm',
      ),
      _plantingCard(
        'Urban Oasis Nursery',
        'Sarah Jenkins',
        'New York, USA',
        '\$15.00-280.00',
        'market',
      ),
      _plantingCard(
        'Green Meadow Agronomics',
        'David Miller',
        'Ohio, USA',
        '\$30.00-500.00',
        'strawberries',
      ),
    ],
  );

  Widget _plantingCard(
    String title,
    String farmer,
    String loc,
    String price,
    String photo,
  ) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Harvest.border),
      boxShadow: Harvest.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Photo(photo, height: 130, width: double.infinity, radius: 0),
        ),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$farmer · $loc',
                    style: const TextStyle(color: Harvest.muted, fontSize: 11),
                  ),
                ],
              ),
              Text(
                price,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF10B981),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _buildMarketProduceView(List<Product> filtered, HarvestStore store) =>
      CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Row(
                children: [
                  Expanded(
                    child: SearchBox(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      hint: 'Search produce, farms, markets…',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: _showFilterSheet,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                (_selectedFarmId != null ||
                                    _onlyInStock ||
                                    _category != 'All')
                                ? Harvest.forest
                                : Harvest.border,
                            width: 1.2,
                          ),
                        ),
                        child: Icon(
                          Icons.tune,
                          size: 20,
                          color:
                              (_selectedFarmId != null ||
                                  _onlyInStock ||
                                  _category != 'All')
                              ? Harvest.forest
                              : Harvest.ink,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: ['All', ...store.categories].map((c) {
                    final sel = _category == c;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(c),
                        selected: sel,
                        selectedColor: Harvest.forest,
                        backgroundColor: Colors.white,
                        labelStyle: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : Harvest.ink,
                        ),
                        side: BorderSide(
                          color: sel ? Harvest.forest : Harvest.border,
                          width: 1,
                        ),
                        onSelected: (_) => setState(() => _category = c),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
          if (filtered.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_outlined,
                title: 'No fresh matches',
                message: 'Try adjusting your search terms, removing filters, or browsing other local farms.',
                action: 'Reset Filters',
                onAction: () => setState(() {
                  _search.clear();
                  _category = 'All';
                  _selectedFarmId = null;
                  _onlyInStock = false;
                }),
              ),
            )
          else ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '${filtered.length} fresh finds',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Harvest.muted,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              sliver: SliverToBoxAdapter(
                child: ProductGrid(
                  products: filtered,
                  onOpen: (p) {
                    store.rememberSearch(p.name);
                    openPage(context, ProductScreen(product: p));
                  },
                ),
              ),
            ),
          ],
        ],
      );
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
        title: const Text(
          'Farm Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Harvest.ink,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircularNavButton(
              icon: isSaved ? Icons.favorite : Icons.favorite_border,
              iconColor: isSaved ? Harvest.tomato : Harvest.ink,
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
                        borderRadius: BorderRadius.all(
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isSelected ? Harvest.forest : Harvest.border,
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
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(32),
                topRight: Radius.circular(32),
              ),
              boxShadow: [
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
                // Product Title & Price Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: Text(p.name, style: Harvest.editorial(26))),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${money(p.price)}/pcs',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Harvest.forest,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Stock Badge & Rating & Stepper Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.stock > 0 ? 'Available in stock' : 'Out of stock',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: p.stock > 0
                                  ? const Color(0xFF10B981)
                                  : Harvest.tomato,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Color(0xFFF59E0B),
                                size: 16,
                              ),
                              SizedBox(width: 4),
                              Text(
                                '4.9 (192)',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Harvest.muted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Counter Stepper [- 1pcs +] matching reference
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Harvest.canvas,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Harvest.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Harvest.forest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.remove,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              '${_quantity}pcs',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Harvest.ink,
                              ),
                            ),
                          ),
                          InkWell(
                            borderRadius: BorderRadius.circular(18),
                            onTap: (p.stock > 0 && _quantity < p.stock)
                                ? () => setState(() => _quantity++)
                                : null,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: const BoxDecoration(
                                color: Harvest.forest,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Description Heading & Expandable Text
                const Text(
                  'Description',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Harvest.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  p.description.isEmpty
                      ? 'Limes are closely related to lemons. They even look similar to them. Lime tree harvest is packed with natural antioxidants and grown organically without synthetic pesticides.'
                      : p.description,
                  maxLines: _isDescriptionExpanded ? null : 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Harvest.muted,
                    height: 1.5,
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
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Harvest.forest,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Related Products Strip matching Reference 1 (Screen 2)
                const Text(
                  'Related Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Harvest.ink,
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
                const SizedBox(height: 24),

                // Local Farmer Info Card
                InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => openPage(context, FarmScreen(farm: farm)),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Harvest.canvas,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Harvest.border),
                    ),
                    child: Row(
                      children: [
                        Photo(farm.image, width: 46, height: 46, radius: 14),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                farm.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                farm.location,
                                style: const TextStyle(
                                  color: Harvest.muted,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Harvest.muted,
                        ),
                      ],
                    ),
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
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Harvest.border),
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
          style: const TextStyle(fontSize: 12, color: Harvest.muted),
        ),
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: Harvest.muted,
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
      backgroundColor: Harvest.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
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
                  Eyebrow(f.market),
                  const SizedBox(height: 6),
                  Text(f.name, style: Harvest.editorial(32)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Harvest.muted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        f.location,
                        style: const TextStyle(
                          color: Harvest.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    f.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Harvest.ink,
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

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final savedProducts = store.products
        .where((p) => store.saved.contains(p.id))
        .toList();

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        title: const Text(
          'Saved for Later',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: savedProducts.isEmpty
          ? EmptyState(
              icon: Icons.favorite_border,
              title: 'Save something fresh',
              message: 'Keep your favourite local produce close at hand. Tap the heart on any harvest to save it for later.',
              action: 'Explore fresh picks',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                PageHeading(
                  'Saved Harvests',
                  eyebrow: '${savedProducts.length} items saved',
                  subtitle: 'Items stay saved in your personal pantry list.',
                ),
                ProductGrid(
                  products: savedProducts,
                  onOpen: (p) => openPage(context, ProductScreen(product: p)),
                ),
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
    final items = store.basket.entries.map((e) {
      final p = store.product(e.key)!;
      return (p, e.value);
    }).toList();

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        title: const Text(
          'Your Basket',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (items.isNotEmpty)
            TextButton(
              onPressed: () => store.clearBasket(),
              child: const Text(
                'Clear',
                style: TextStyle(color: Harvest.danger, fontSize: 12),
              ),
            ),
        ],
      ),
      body: items.isEmpty
          ? EmptyState(
              icon: Icons.shopping_basket_outlined,
              title: 'Your basket is empty',
              message: 'Browse our local growers to discover fruits, vegetables, and pantry items harvested fresh today.',
              action: 'Start Shopping',
              onAction: () => Navigator.pop(context),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                PageHeading(
                  'Market Basket',
                  eyebrow: '${store.basketCount} items from local farms',
                  subtitle:
                      'Direct from field to table with zero intermediaries.',
                ),
                for (final (p, qty) in items) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Harvest.border),
                      boxShadow: Harvest.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Photo(
                          p.image,
                          bytes: p.photo,
                          width: 68,
                          height: 68,
                          radius: 14,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${money(p.price)} / ${p.unit}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Harvest.muted,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                money(p.price * qty),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Harvest.forest,
                                ),
                              ),
                            ],
                          ),
                        ),
                        QuantityStepper(
                          value: qty,
                          max: p.stock,
                          onChanged: (newQty) =>
                              store.setQuantity(p.id, newQty),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Order summary breakdown
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Harvest.border),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Subtotal',
                            style: TextStyle(color: Harvest.muted),
                          ),
                          Text(
                            money(store.basketTotal),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Simulated Delivery',
                            style: TextStyle(color: Harvest.muted),
                          ),
                          Text(
                            'Free',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Harvest.success,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Amount',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            money(store.basketTotal),
                            style: Harvest.editorial(22, color: Harvest.forest),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: items.isEmpty
          ? null
          : BottomAction(
              child: HarvestButton(
                label: 'Continue to Checkout · ${money(store.basketTotal)}',
                onPressed: () => openPage(context, const CheckoutScreen()),
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
  String _selectedPickupSlot = 'Morning (9:00 AM - 12:00 PM)';
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
      notice(context, 'Please enter a valid delivery address', isError: true);
      return;
    }

    setState(() => _busy = true);
    await Future<void>.delayed(Duration.zero);
    {
      if (!mounted) return;
      try {
        final created = await store.checkout(_address.text.trim());
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => ConfirmationScreen(orders: created),
          ),
        );
      } catch (e) {
        notice(context, e.toString(), isError: true);
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        title: const Text(
          'Review Order',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        children: [
          const PageHeading(
            'Order Confirmation',
            eyebrow: 'Simulated Order Placement',
            subtitle: 'Per SRS specifications, no actual payment gateway is involved. Review and confirm below.',
          ),
          const InfoNote(
            'Demonstration Mode: Confirming this order updates inventory and sends orders directly to your farmer queue.',
          ),
          const SizedBox(height: 20),

          const Text(
            'Delivery Address',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _address,
            maxLines: 2,
            decoration: const InputDecoration(
              hintText: 'Enter street, neighborhood, city…',
              prefixIcon: Icon(
                Icons.location_on_outlined,
                color: Harvest.forest,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Optional Pickup Slot module (per SRS Section 16 & 32)
          const Text(
            'Pickup / Delivery Window (Optional)',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children:
                [
                  'Morning (9:00 AM - 12:00 PM)',
                  'Afternoon (2:00 PM - 5:00 PM)',
                ].map((slot) {
                  final sel = _selectedPickupSlot == slot;
                  return ChoiceChip(
                    label: Text(slot),
                    selected: sel,
                    selectedColor: Harvest.forest,
                    labelStyle: TextStyle(
                      color: sel ? Colors.white : Harvest.ink,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (_) =>
                        setState(() => _selectedPickupSlot = slot),
                  );
                }).toList(),
          ),
          const SizedBox(height: 24),

          // Basket items review
          const Text(
            'Ordered Items',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 10),
          for (final entry in store.basket.entries) ...[
            Builder(
              builder: (context) {
                final p = store.product(entry.key);
                if (p == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        '${entry.value}x',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: Harvest.forest,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        money(p.price * entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total to confirm',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
              ),
              Text(
                money(store.basketTotal),
                style: Harvest.editorial(24, color: Harvest.forest),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: 'Confirm order · ${money(store.basketTotal)}',
          busy: _busy,
          onPressed: _busy ? null : _confirm,
        ),
      ),
    );
  }
}

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({super.key, required this.orders});
  final List<HarvestOrder> orders;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Harvest.cream,
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
              decoration: const BoxDecoration(
                color: Harvest.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                size: 48,
                color: Harvest.forest,
              ),
            ),
            const SizedBox(height: 24),
            Text('Order confirmed', style: Harvest.editorial(32)),
            const SizedBox(height: 10),
            Text(
              'Your order ${orders.map((o) => o.id).join(', ')} has been placed directly with the growers.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Harvest.muted,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Harvest.border),
              ),
              child: Column(
                children: [
                  for (final o in orders)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          o.farmName,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          money(o.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Harvest.forest,
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
class TodaysWeatherScreen extends StatefulWidget {
  const TodaysWeatherScreen({super.key});

  @override
  State<TodaysWeatherScreen> createState() => _TodaysWeatherScreenState();
}

class _TodaysWeatherScreenState extends State<TodaysWeatherScreen> {
  final List<({String photo, String timestamp, String note})> _notes = [
    (
      photo: 'farm',
      timestamp: 'May 24 . 5:43pm',
      note: 'Excellent harvest, the grapes have a rich flavor and aroma',
    ),
    (
      photo: 'tomatoes',
      timestamp: 'May 24 . 3:15pm',
      note:
          'Foliage canopy inspected, healthy fruit set with zero blight signs',
    ),
    (
      photo: 'strawberries',
      timestamp: 'May 23 . 10:20am',
      note: 'Sweet aroma rising from rows, sugar brix testing at 12.4 degrees',
    ),
    (
      photo: 'potatoes',
      timestamp: 'May 22 . 8:45am',
      note: 'Optimal tuber formation, soil moisture maintained at 72%',
    ),
  ];

  void _showAddNoteDialog() {
    final noteCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Crop Field Note',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText:
                    'Record observations (e.g. soil moisture, harvest aroma)…',
                fillColor: Harvest.canvas,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Harvest.border),
                ),
              ),
            ),
            const SizedBox(height: 18),
            HarvestButton(
              label: 'Save Field Note',
              icon: Icons.check,
              onPressed: () {
                final txt = noteCtrl.text.trim();
                if (txt.isNotEmpty) {
                  setState(() {
                    _notes.insert(0, (
                      photo: 'farm',
                      timestamp: 'Just now',
                      note: txt,
                    ));
                  });
                  HapticFeedback.lightImpact();
                  Navigator.pop(ctx);
                  notice(context, 'Field observation recorded');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
      title: const Text(
        'Todays Weather',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Harvest.ink,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircularNavButton(
            icon: Icons.notifications_none_outlined,
            hasBadge: true,
            onPressed: () =>
                notice(context, 'Advisory: Optimal harvest conditions today!'),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
      children: [
        // 1. Deep Emerald Weather Banner matching Reference 1 (Screen 3)
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Harvest.forest,
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                color: Harvest.forest.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    color: Color(0xFFD4E3D7),
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Bekasi Timur, 27 Nov 2023',
                    style: TextStyle(
                      color: Color(0xFFD4E3D7),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '33 °C',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Humidity 76%',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.cloud_queue_rounded,
                          color: Color(0xFFFDE68A),
                          size: 34,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Cloudy',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.eco, color: Color(0xFF34D399), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Today is a good day to apply pesticides.',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 2. Crop Notes Section matching Reference 1 (Screen 3)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Harvest.ink,
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.arrow_forward,
                size: 20,
                color: Harvest.muted,
              ),
              onPressed: _showAddNoteDialog,
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (final item in _notes)
          CropNoteTile(
            photo: item.photo,
            timestamp: item.timestamp,
            note: item.note,
            onTap: () => notice(context, 'Field log: ${item.note}'),
          ),
      ],
    ),
    bottomNavigationBar: BottomAction(
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: FilledButton.icon(
          icon: const Icon(Icons.add, size: 20, color: Colors.white),
          label: const Text(
            'Add New Note',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: Harvest.forest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: _showAddNoteDialog,
        ),
      ),
    ),
  );
}

/// Statistic Screen matching Reference Image 2 (Screen 4)
class StatisticScreen extends StatefulWidget {
  const StatisticScreen({super.key});

  @override
  State<StatisticScreen> createState() => _StatisticScreenState();
}

class _StatisticScreenState extends State<StatisticScreen> {
  String _period = 'Weekly';
  final Set<String> _joinedCommunities = {'Farming Community'};

  final List<({String name, String author, String location, String photo})>
  _communities = [
    (
      name: 'Farming Community',
      author: 'Gun Hawkins',
      location: 'New York, USA',
      photo: 'farm',
    ),
    (
      name: 'Agriculture Community',
      author: 'Gun Hawkins',
      location: 'New York, USA',
      photo: 'market',
    ),
    (
      name: 'Organic Growers Guild',
      author: 'Elena Vance',
      location: 'California, USA',
      photo: 'tomatoes',
    ),
    (
      name: 'Permaculture Collective',
      author: 'Marcus Thorne',
      location: 'Oregon, USA',
      photo: 'strawberries',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
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
      title: const Text(
        'Statistic',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Harvest.ink,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircularNavButton(
            icon: Icons.notifications_none_outlined,
            hasBadge: true,
            onPressed: () =>
                notice(context, 'Growth alert: Sprout reached 9.5cm!'),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      children: [
        // 1. Growth Spline Area Chart matching Reference 2 (Screen 4)
        GrowthAreaChart(
          title: 'Growth',
          period: _period,
          onPeriodChange: () {
            setState(() {
              _period = _period == 'Weekly' ? 'Monthly' : 'Weekly';
            });
            HapticFeedback.selectionClick();
          },
        ),
        const SizedBox(height: 28),

        // 2. Community List matching Reference 2 (Screen 4)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Community',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Harvest.ink,
              ),
            ),
            TextButton(
              onPressed: () =>
                  notice(context, 'Showing all verified local grower circles'),
              child: const Text(
                'View all',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (final comm in _communities)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 10,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Photo(comm.photo, width: 48, height: 48, radius: 14),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comm.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Harvest.ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${comm.author} · ${comm.location}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Harvest.muted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 32,
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        if (_joinedCommunities.contains(comm.name)) {
                          _joinedCommunities.remove(comm.name);
                        } else {
                          _joinedCommunities.add(comm.name);
                        }
                      });
                      HapticFeedback.lightImpact();
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _joinedCommunities.contains(comm.name)
                          ? Colors.white
                          : Harvest.forest,
                      backgroundColor: _joinedCommunities.contains(comm.name)
                          ? Harvest.forest
                          : Colors.white,
                      side: BorderSide(
                        color: _joinedCommunities.contains(comm.name)
                            ? Harvest.forest
                            : Harvest.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                    ),
                    child: Text(
                      _joinedCommunities.contains(comm.name)
                          ? 'Joined'
                          : 'Gabung',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

/// Planting Screen matching Reference Image 2 (Screen 5)
class PlantingScreen extends StatefulWidget {
  const PlantingScreen({super.key});

  @override
  State<PlantingScreen> createState() => _PlantingScreenState();
}

class _PlantingScreenState extends State<PlantingScreen> {
  int _selectedTab = 0; // 0: Farming, 1: Nursery
  final Set<String> _favorites = {};

  final List<
    ({
      String title,
      String farmer,
      String location,
      String price,
      double rating,
      String photo,
    })
  >
  _items = [
    (
      title: 'Spring Serenade Farming',
      farmer: 'Robert Fox',
      location: 'New York, USA',
      price: '\$22.00-400.00',
      rating: 4.8,
      photo: 'farm',
    ),
    (
      title: 'Urban Oasis Nursery',
      farmer: 'Sarah Jenkins',
      location: 'New York, USA',
      price: '\$15.00-280.00',
      rating: 4.9,
      photo: 'market',
    ),
    (
      title: 'Green Meadow Agronomics',
      farmer: 'David Miller',
      location: 'Ohio, USA',
      price: '\$30.00-500.00',
      rating: 4.7,
      photo: 'strawberries',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
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
      title: const Text(
        'Planting',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Harvest.ink,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircularNavButton(
            icon: Icons.notifications_none_outlined,
            hasBadge: true,
            onPressed: () =>
                notice(context, 'Planting season: Perfect germination window!'),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      children: [
        // 1. Segmented Toggle [Farming | Nursery] matching Reference 2 (Screen 5)
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Harvest.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedTab = 0),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 0
                          ? Harvest.forest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Farming',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 0 ? Colors.white : Harvest.muted,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => setState(() => _selectedTab = 1),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: _selectedTab == 1
                          ? Harvest.forest
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'Nursery',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _selectedTab == 1 ? Colors.white : Harvest.muted,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 2. Search Box with Mic Icon
        Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Harvest.border),
          ),
          child: const Row(
            children: [
              Icon(Icons.search, color: Harvest.muted, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search here...',
                  style: TextStyle(color: Harvest.muted, fontSize: 14),
                ),
              ),
              Icon(Icons.mic_none_rounded, color: Harvest.muted, size: 20),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // 3. Farmer Story Cards
        for (final item in _items)
          Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Harvest.border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 14,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                      child: Photo(
                        item.photo,
                        height: 160,
                        width: double.infinity,
                        radius: 0,
                      ),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Color(0xFFF59E0B),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.rating}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            if (_favorites.contains(item.title)) {
                              _favorites.remove(item.title);
                            } else {
                              _favorites.add(item.title);
                            }
                          });
                          HapticFeedback.lightImpact();
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _favorites.contains(item.title)
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: Harvest.tomato,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Harvest.ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(
                            Icons.person_outline,
                            size: 14,
                            color: Harvest.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.farmer,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Harvest.muted,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Harvest.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Harvest.muted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.price,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
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
  );
}

/// All Farm Directory Screen matching Reference Image 2 (Screen 6)
class AllFarmsScreen extends StatefulWidget {
  const AllFarmsScreen({super.key});

  @override
  State<AllFarmsScreen> createState() => _AllFarmsScreenState();
}

class _AllFarmsScreenState extends State<AllFarmsScreen> {
  int _selectedFilter = 0; // 0: Regular, 1: Shariah

  final List<
    ({String name, String earnings, String price, String period, String photo})
  >
  _farms = [
    (
      name: 'Cucumber Farm 13',
      earnings: '5.5%',
      price: '10,000 BDT/share',
      period: '4 Months',
      photo: 'farm',
    ),
    (
      name: 'Agriculture Farm 27',
      earnings: '5.5%',
      price: '10,000 BDT/share',
      period: '4 Months',
      photo: 'market',
    ),
    (
      name: 'Korolla Farm 18',
      earnings: '5.5%',
      price: '10,000 BDT/share',
      period: '4 Months',
      photo: 'strawberries',
    ),
    (
      name: 'Enrichment Farm 7',
      earnings: '5.5%',
      price: '10,000 BDT/share',
      period: '4 Months',
      photo: 'potatoes',
    ),
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
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
      title: const Text(
        'All Farm',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: Harvest.ink,
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: CircularNavButton(
            icon: Icons.notifications_none_outlined,
            hasBadge: true,
            onPressed: () =>
                notice(context, 'Farm alert: New harvest shares open!'),
          ),
        ),
      ],
    ),
    body: ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      children: [
        // 1. Segmented Toggle [Regular | Shariah] + filter icon
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Harvest.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _selectedFilter = 0),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFilter == 0
                                ? Harvest.forest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Regular',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _selectedFilter == 0
                                  ? Colors.white
                                  : Harvest.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () => setState(() => _selectedFilter = 1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _selectedFilter == 1
                                ? Harvest.forest
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            'Shariah',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: _selectedFilter == 1
                                  ? Colors.white
                                  : Harvest.muted,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Harvest.border),
              ),
              child: const Icon(Icons.tune, color: Harvest.forest, size: 20),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // 2. Active Farms Section
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Active Farms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Harvest.ink,
              ),
            ),
            TextButton(
              onPressed: () =>
                  notice(context, 'Showing all verified agricultural listings'),
              child: const Text(
                'View all',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        for (final f in _farms)
          FarmDirectoryCard(
            name: f.name,
            earnings: f.earnings,
            price: f.price,
            period: f.period,
            photo: f.photo,
            onTap: () {
              HapticFeedback.mediumImpact();
              notice(context, 'Investment booking initiated for ${f.name}');
            },
          ),
      ],
    ),
  );
}
