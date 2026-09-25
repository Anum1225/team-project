import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../models/product.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/heading.dart';
import '../widgets/product_grid.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.store,
    this.initialCategory = 'All',
  });
  final CustomerStore store;
  final String initialCategory;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String category = widget.initialCategory;
  final search = TextEditingController();
  String farmer = 'All', market = 'All', location = 'All', sort = 'Featured';
  double distance = 20;
  bool inStock = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Product> get filtered {
    final query = search.text.trim().toLowerCase();
    final list = products
        .where(
          (p) =>
              (category == 'All' ||
                  p.category == category ||
                  category == 'Organic' && p.organic) &&
              '${p.name} ${p.category} ${p.farmer.name} ${p.farmer.market} ${p.farmer.location}'
                  .toLowerCase()
                  .contains(query) &&
              (farmer == 'All' || p.farmerId == farmer) &&
              (market == 'All' || p.farmer.market == market) &&
              (location == 'All' || p.farmer.location == location) &&
              p.farmer.distance <= distance &&
              (!inStock || widget.store.stock(p) > 0),
        )
        .toList();
    if (sort == 'Price: low to high') {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    if (sort == 'Price: high to low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    if (sort == 'Nearest farm') {
      list.sort((a, b) => a.farmer.distance.compareTo(b.farmer.distance));
    }
    return list;
  }

  Future<void> filters() async {
    var nextFarmer = farmer, nextMarket = market, nextLocation = location;
    var nextDistance = distance;
    var nextStock = inStock;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Heading(
                  'Find your kind of fresh',
                  subtitle: 'Filter by the farms and markets near you.',
                ),
                DropdownButtonFormField<String>(
                  initialValue: nextFarmer,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Farmer'),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All farmers'),
                    ),
                    ...farmers.map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    ),
                  ],
                  onChanged: (v) => update(() => nextFarmer = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextMarket,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Market'),
                  items: ['All', ...farmers.map((f) => f.market).toSet()]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'All' ? 'All markets' : v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => nextMarket = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextLocation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: ['All', 'Clifton', 'Gulshan']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'All' ? 'All locations' : v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => nextLocation = v!),
                ),
                const SizedBox(height: 20),
                Text('Within ${nextDistance.round()} km'),
                Slider(
                  value: nextDistance,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${nextDistance.round()} km',
                  onChanged: (v) => update(() => nextDistance = v),
                ),
                const Text(
                  'Distances are sample values from central Karachi.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only show available products'),
                  value: nextStock,
                  onChanged: (v) => update(() => nextStock = v),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      farmer = nextFarmer;
                      market = nextMarket;
                      location = nextLocation;
                      distance = nextDistance;
                      inStock = nextStock;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply filters'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      farmer = market = location = 'All';
                      distance = 20;
                      inStock = false;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Heading(
          'Explore the harvest',
          subtitle: 'Fresh food. Real growers. A better everyday basket.',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Products, farmers or markets',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(search.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: filters,
              tooltip: 'Search filters',
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          children: [
            Text(
              '${items.length} fresh finds',
              style: const TextStyle(color: muted),
            ),
            DropdownButton<String>(
              value: sort,
              underline: const SizedBox.shrink(),
              items:
                  [
                        'Featured',
                        'Price: low to high',
                        'Price: high to low',
                        'Nearest farm',
                      ]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => sort = v!),
            ),
          ],
        ),
        if (items.isEmpty)
          EmptyState(
            Icons.search_off,
            'No fresh finds yet',
            'Try another keyword or broaden your filters.',
            action: TextButton(
              onPressed: () => setState(() {
                search.clear();
                category = farmer = market = location = 'All';
                distance = 20;
                inStock = false;
              }),
              child: const Text('Clear all filters'),
            ),
          )
        else
          ProductGrid(items: items, store: widget.store),
      ],
    );
  }
}
