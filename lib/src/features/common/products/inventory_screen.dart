part of '../management/operations.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';
  String _category = 'All';
  bool _showSearchBar = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final admin = store.role == UserRole.admin;
    final query = _search.text.toLowerCase().trim();

    final products = store.visibleProducts.where((p) {
      if (query.isNotEmpty &&
          !'${p.name} ${store.farm(p.farmId).name} ${p.farmId}'
              .toLowerCase()
              .contains(query)) {
        return false;
      }
      if (_category != 'All' && p.category != _category) return false;
      if (_filter == 'Active' && p.stock <= 0) return false;
      if (_filter == 'Low stock' && (p.stock <= 0 || p.stock > 5)) return false;
      if (_filter == 'Out of stock' && p.stock != 0) return false;
      return true;
    }).toList();

    final categoryCounts = <String, int>{'All': store.visibleProducts.length};
    for (final c in store.categories) {
      categoryCounts[c] = store.visibleProducts
          .where((p) => p.category == c)
          .length;
    }

    final categoryTabs = ['All', ...store.categories];

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: Text(
          admin ? 'Products' : 'My Products',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Search products',
            icon: Icon(
              _showSearchBar ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () => setState(() {
              _showSearchBar = !_showSearchBar;
              if (!_showSearchBar) _search.clear();
            }),
          ),
          IconButton(
            tooltip: 'Filter',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () {
              // Toggle stock filter cycle
              setState(() {
                _filter = switch (_filter) {
                  'All' => 'Active',
                  'Active' => 'Low stock',
                  'Low stock' => 'Out of stock',
                  _ => 'All',
                };
              });
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => openPage(context, const ProductEditorScreen()),
                icon: const Icon(
                  Icons.add_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                label: const Text(
                  'Add',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5631),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_showSearchBar)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: SearchBox(
                controller: _search,
                hint: 'Search products by name…',
                managementStyle: store.role == UserRole.admin,
                onChanged: (_) => setState(() {}),
              ),
            ),

          // Horizontal category tabs matching reference images
          Container(
            height: 48,
            margin: const EdgeInsets.only(top: 4, bottom: 8),
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: categoryTabs.length,
              separatorBuilder: (context, index) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final cat = categoryTabs[i];
                final isSelected = _category == cat;
                final count = categoryCounts[cat] ?? 0;
                final label = admin ? '$cat ($count)' : cat;

                return Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => setState(() => _category = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF1E5631)
                            : Harvest.colors(context).surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF1E5631)
                              : Harvest.colors(context).border,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (cat != 'All') ...[
                            Text(switch (cat.toLowerCase()) {
                              'vegetables' => '🥦',
                              'fruits' => '🍎',
                              'dairy' => '🥛',
                              'grains' => '🌾',
                              'herbs' => '🌿',
                              _ => '📦',
                            }, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 6),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Harvest.colors(context).ink,
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

          // Product list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
              children: [
                if (products.isEmpty)
                  const EmptyState(
                    title: 'No products in this view',
                    message: 'Add your first harvest item or change your search filter.',
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  for (final p in products) InventoryRow(product: p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
