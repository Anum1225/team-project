part of '../customer.dart';

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
      useSafeArea: true,
      backgroundColor: Harvest.colors(context).surface,
      clipBehavior: Clip.antiAlias,
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
                for (final farm in store.farms.where((farm) => farm.active))
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
                  onLocationSelected: (value) {
                    update(() {
                      latitude = value.latitude;
                      longitude = value.longitude;
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
    final products = store.catalogProducts(
      store.products.where((product) {
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
      }),
    );
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
                    hint: 'Search produce or farms',
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
                      final scale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final cardWidth =
                          (constraints.maxWidth - 36 - (columns - 1) * 14) /
                          columns;
                      return GridView.builder(
                        padding: const EdgeInsets.fromLTRB(18, 4, 18, 24),
                        itemCount: products.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          mainAxisExtent:
                              (cardWidth - 20) / 1.15 + 60 + 96 * scale,
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
