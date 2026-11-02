import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'auth.dart';
import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'orders.dart';
import 'profile.dart';
import 'reporting.dart';
import 'store.dart';
import 'theme.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.onProducts,
    required this.onOrders,
  });

  final VoidCallback onProducts, onOrders;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _reportRequested = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_reportRequested) {
      _reportRequested = true;
      HarvestScope.of(context).loadReport(7);
    }
  }

  Future<void> _refresh(HarvestStore store) async {
    await store.refresh();
    await store.loadReport(7);
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.role == UserRole.admin) {
      return AdminDashboard(
        onProducts: widget.onProducts,
        onOrders: widget.onOrders,
      );
    }
    final palette = Harvest.colors(context);
    final farm = store.ownFarm;
    final products = store.visibleProducts;
    final orders = store.visibleOrders;
    final pending = orders.where((o) => o.status.active).length;
    final stock = products.fold<int>(0, (sum, product) => sum + product.stock);
    final report = store.report;
    final trend = ((report?['trend'] as List?) ?? const [])
        .map((value) => (value as num).toDouble())
        .toList();
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
        ? 'Good afternoon'
        : 'Good evening';
    final lowStock = products
        .where((product) => product.stock <= 5)
        .take(4)
        .toList();
    final latestOrders = orders.take(4).toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _refresh(store),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 34),
            children: [
              HarvestHubBrandHeader(
                marketName: farm.market.trim().isNotEmpty
                    ? farm.market
                    : farm.location.trim().isNotEmpty
                    ? farm.location
                    : 'Your farm',
                unreadNotifications: false,
                onLocationTap: () =>
                    openPage(context, const FarmEditorScreen()),
                onNotificationTap: widget.onOrders,
                onProfileTap: () => openPage(
                  context,
                  ProfileScreen(onExit: () => Navigator.maybePop(context)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, ${store.account.name.split(' ').first}',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      farm.name,
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF164A31),
                      Color(0xFF257549),
                      Color(0xFF438953),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x25255035),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: Color(0xFFBDE8BE),
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'YOUR HARVEST, IN ONE PLACE',
                          style: TextStyle(
                            color: Color(0xFFD8F1D7),
                            fontSize: 10,
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      farm.description.trim().isNotEmpty
                          ? farm.description
                          : 'Keep your farm profile and fresh stock up to date.',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 10,
                      runSpacing: 8,
                      children: [
                        FilledButton.icon(
                          onPressed: () =>
                              openPage(context, const ProductEditorScreen()),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFFE3B548),
                            foregroundColor: const Color(0xFF18351F),
                          ),
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add a product'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () =>
                              openPage(context, const FarmEditorScreen()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white70),
                          ),
                          icon: const Icon(Icons.storefront_outlined),
                          label: const Text('Farm profile'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _farmerMetric(
                      context,
                      'Products',
                      '${products.length}',
                      Icons.inventory_2_outlined,
                      () => widget.onProducts(),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _farmerMetric(
                      context,
                      'Units in stock',
                      '$stock',
                      Icons.spa_outlined,
                      () => widget.onProducts(),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _farmerMetric(
                      context,
                      'Open orders',
                      '$pending',
                      Icons.receipt_long_outlined,
                      () => widget.onOrders(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Last 7 days', 'Order value'),
              const SizedBox(height: 10),
              _surface(
                context,
                child: trend.isEmpty || trend.every((v) => v == 0)
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: InfoNote(
                          'No order value recorded this week yet.',
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
                        child: OrderValueChart(values: trend),
                      ),
              ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Needs attention', 'Low stock'),
              const SizedBox(height: 10),
              if (lowStock.isEmpty)
                _surface(
                  context,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: InfoNote('No products are running low on stock.'),
                  ),
                )
              else
                for (final product in lowStock)
                  _surface(
                    context,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: const CircleAvatar(
                        child: Icon(Icons.inventory_2_outlined),
                      ),
                      title: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${product.stock} ${product.unit} left'),
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: palette.muted,
                      ),
                      onTap: () => openPage(
                        context,
                        ProductEditorScreen(product: product),
                      ),
                    ),
                  ),
              const SizedBox(height: 20),
              _sectionTitle(context, 'Recent activity', 'Orders'),
              const SizedBox(height: 10),
              if (latestOrders.isEmpty)
                _surface(
                  context,
                  child: const Padding(
                    padding: EdgeInsets.all(16),
                    child: InfoNote('Your customer orders will appear here.'),
                  ),
                )
              else
                for (final order in latestOrders)
                  _surface(
                    context,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 2,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: palette.paleLeaf,
                        child: Icon(
                          Icons.receipt_long_rounded,
                          color: palette.green,
                        ),
                      ),
                      title: Text(
                        order.customerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text('${order.id} · ${dateLabel(order.date)}'),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            order.status.label,
                            style: TextStyle(
                              color: palette.green,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            money(order.total),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                      onTap: widget.onOrders,
                    ),
                  ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: widget.onProducts,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                  label: const Text('Open inventory'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _farmerMetric(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    VoidCallback onTap,
  ) {
    final palette = Harvest.colors(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
        decoration: BoxDecoration(
          color: palette.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: palette.green, size: 19),
            const SizedBox(height: 9),
            Text(
              value,
              maxLines: 1,
              style: TextStyle(
                color: palette.ink,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: palette.muted,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, String action) {
    final palette = Harvest.colors(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              color: palette.ink,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          action,
          style: TextStyle(
            color: palette.green,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _surface(BuildContext context, {required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: Material(
      color: Harvest.colors(context).surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Harvest.colors(context).border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    ),
  );
}

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
                    message:
                        'Add your first harvest item or change your search filter.',
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
                    p.image,
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

class ProductEditorScreen extends StatefulWidget {
  const ProductEditorScreen({super.key, this.product});
  final Product? product;

  @override
  State<ProductEditorScreen> createState() => _ProductEditorScreenState();
}

class _ProductEditorScreenState extends State<ProductEditorScreen> {
  final GlobalKey<FormState> _form = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _price = TextEditingController();
  final TextEditingController _stock = TextEditingController();
  final TextEditingController _description = TextEditingController();
  final TextEditingController _unit = TextEditingController();

  String? _category;
  String? _farmId;
  String? _error;
  String _image = '';
  Uint8List? _photo;
  bool _initialized = false;
  bool _picking = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final store = HarvestScope.of(context);
    final p = widget.product;
    _name.text = p?.name ?? '';
    _price.text = p == null ? '' : (p.price / 100).toStringAsFixed(0);
    _stock.text = p?.stock.toString() ?? '';
    _description.text = p?.description ?? '';
    _unit.text = p?.unit ?? 'kg';
    _category = p?.category ?? store.categories.firstOrNull;
    _farmId =
        p?.farmId ??
        (store.role == UserRole.farmer
            ? store.ownFarm.id
            : store.farms.firstOrNull?.id);
    _image = p?.image ?? 'tomatoes';
    _photo = p?.photo;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _stock.dispose();
    _description.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() => _picking = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1400,
        imageQuality: 85,
      );
      if (file == null) return;
      if (await file.length() > 8 * 1024 * 1024) {
        if (mounted) {
          setState(() => _error = 'Choose an image smaller than 8 MB.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (mounted) {
        setState(() {
          _photo = bytes;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not open image. Please check permissions.',
        );
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    final store = HarvestScope.of(context);
    if (_category == null || _farmId == null) {
      setState(() => _error = 'Farm and category must be selected.');
      return;
    }
    final value = Product(
      id: widget.product?.id ?? 'p-${DateTime.now().microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category!,
      farmId: _farmId!,
      price: (double.parse(_price.text) * 100).round(),
      stock: int.parse(_stock.text),
      image: _image,
      photo: _photo,
      unit: _unit.text.trim().isEmpty ? 'kg' : _unit.text.trim(),
      description: _description.text.trim(),
    );
    final msg = await store.saveProduct(value);
    if (!mounted) return;
    if (msg != null) {
      setState(() => _error = msg);
      return;
    }
    Navigator.pop(context);
    notice(
      context,
      widget.product == null
          ? 'Product added to your farm stand'
          : 'Product updated successfully',
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final p = widget.product;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: Text(
          p == null ? 'Add Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (p != null)
            IconButton(
              tooltip: 'Delete product',
              onPressed: () async {
                if (await confirmAction(
                  context,
                  title: 'Remove this product?',
                  message:
                      'This will remove it from customer catalogs and shopping baskets.',
                  action: 'Remove Product',
                  isDestructive: true,
                )) {
                  final error = await store.deleteProduct(p);
                  if (error != null) {
                    if (context.mounted) notice(context, error, isError: true);
                    return;
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    notice(context, 'Product removed from inventory');
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: Harvest.danger),
            ),
        ],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            // Photo Upload Row matching Image 2 Screen 4
            Row(
              children: [
                // Selected photo preview
                Stack(
                  children: [
                    Container(
                      width: 140,
                      height: 120,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Harvest.colors(context).border,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Photo(
                          _image,
                          bytes: _photo,
                          fit: BoxFit.cover,
                          radius: 18,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: InkWell(
                        onTap: () => setState(() {
                          _photo = null;
                          _image = 'farm';
                        }),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 14),

                // Dashed Add More Photos Card
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _pickImage,
                    child: Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF14241B)
                            : const Color(0xFFF9FBF9),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFF1E5631).withValues(alpha: 0.4),
                          style: BorderStyle.solid,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF1E5631,
                              ).withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.camera_alt_outlined,
                              size: 22,
                              color: Color(0xFF1E5631),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _picking ? 'Opening…' : 'Add More\nPhotos',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Harvest.colors(context).muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Product Name *
            Text(
              'Product Name *',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Harvest.colors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            HarvestField(
              controller: _name,
              label: '',
              hint: 'e.g. Fresh Tomatoes',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Enter product name' : null,
            ),
            const SizedBox(height: 16),

            // Category * Dropdown with icons
            Text(
              'Category *',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Harvest.colors(context).ink,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Harvest.colors(context).border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: Harvest.colors(context).border),
                ),
              ),
              isExpanded: true,
              items: store.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Row(
                        children: [
                          Text(switch (c.toLowerCase()) {
                            'vegetables' => '🍅',
                            'fruits' => '🍎',
                            'dairy' => '🥛',
                            'grains' => '🌾',
                            'herbs' => '🌿',
                            _ => '📦',
                          }, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            c,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Choose a category.' : null,
            ),

            if (store.role == UserRole.admin) ...[
              const SizedBox(height: 16),
              Text(
                'Farm Origin *',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Harvest.colors(context).ink,
                ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _farmId,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                isExpanded: true,
                items: store.farms
                    .map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _farmId = v),
                validator: (v) => v == null ? 'Choose a farm.' : null,
              ),
            ],
            const SizedBox(height: 16),

            // Price (Rs.) * and Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Price (Rs.) *',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      HarvestField(
                        controller: _price,
                        label: '',
                        hint: '120',
                        keyboard: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) =>
                            v == null ||
                                double.tryParse(v) == null ||
                                !double.parse(v).isFinite ||
                                double.parse(v) < 0 ||
                                double.parse(v) > 10000000
                            ? 'Enter valid price'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit Type',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _unit.text.isEmpty ? 'kg' : _unit.text,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: ['kg', 'litre', 'dozen', 'pack', 'basket']
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _unit.text = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Stock Quantity * and Unit
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock Quantity *',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      HarvestField(
                        controller: _stock,
                        label: '',
                        hint: '50',
                        keyboard: TextInputType.number,
                        validator: (v) =>
                            v == null ||
                                int.tryParse(v) == null ||
                                int.parse(v) < 0
                            ? 'Enter 0 or positive'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Unit',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Harvest.colors(context).ink,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: _unit.text.isEmpty ? 'kg' : _unit.text,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 12,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        items: ['kg', 'litre', 'units', 'packs']
                            .map(
                              (u) => DropdownMenuItem(
                                value: u,
                                child: Text(u, overflow: TextOverflow.ellipsis),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _unit.text = v);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description with Character Counter
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Description',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Harvest.colors(context).ink,
                  ),
                ),
                Text(
                  '${_description.text.length}/500',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    color: Harvest.colors(context).muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            HarvestField(
              controller: _description,
              label: '',
              hint:
                  'Describe the product, its growing conditions, storage and preparation.',
              lines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),

            if (_error != null) ...[
              const SizedBox(height: 14),
              InfoNote(_error!, error: true),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _picking || store.busy ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E5631),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Save Product',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 16,
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

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  String _period = 'Week';

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.live) return const LiveReports();
    final now = DateTime.now();
    final days = _period == 'Day'
        ? 1
        : _period == 'Week'
        ? 7
        : 30;
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));

    final orders = store.visibleOrders
        .where((o) => !o.date.isBefore(start) && !o.date.isAfter(now))
        .toList();
    final completed = orders
        .where((o) => o.status == OrderStatus.completed)
        .toList();
    final revenue = completed.fold<int>(0, (a, o) => a + o.total);

    final popular = <String, int>{};
    for (final o in completed) {
      for (final line in o.items) {
        popular.update(
          line.name,
          (val) => val + line.quantity,
          ifAbsent: () => line.quantity,
        );
      }
    }
    final ranked = popular.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: const Text(
          'Farm Performance Reports',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeading(
            'Sales & Harvests',
            eyebrow: 'Report Analytics',
            subtitle: 'Overview of completed orders and revenue summaries.',
          ),
          ChoiceRow(
            values: const ['Day', 'Week', 'Month'],
            selected: _period,
            onSelected: (v) => setState(() => _period = v),
          ),
          const SizedBox(height: 12),
          Text(
            '${dateLabel(start)} – ${dateLabel(now)}',
            style: TextStyle(
              fontSize: 12,
              color: Harvest.colors(context).muted,
            ),
          ),
          const SizedBox(height: 20),

          MetricCard(
            label: 'Total Revenue (Completed Orders)',
            value: money(revenue),
            icon: Icons.payments_outlined,
            dark: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: 'Total Orders',
                  value: '${orders.length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Completed Orders',
                  value: '${completed.length}',
                  icon: Icons.task_alt,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated Revenue Trend Chart
          const GrowthAreaChart(
            title: 'Revenue & Volume Trend',
            period: 'Weekly',
          ),
          const SizedBox(height: 24),

          // Order Status Breakdown
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Harvest.colors(context).surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.colors(context).border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Status Progression',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const SizedBox(height: 16),
                for (final status in OrderStatus.values) ...[
                  Builder(
                    builder: (context) {
                      final count = orders
                          .where((o) => o.status == status)
                          .length;
                      final ratio = orders.isEmpty
                          ? 0.0
                          : count / orders.length;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      statusIcon(status),
                                      size: 14,
                                      color: Harvest.colors(context).muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      status.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '$count',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: ratio,
                                minHeight: 6,
                                backgroundColor: Harvest.colors(
                                  context,
                                ).paleLeaf,
                                color: status == OrderStatus.cancelled
                                    ? Harvest.danger
                                    : Harvest.forest,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Most popular products
          if (ranked.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Harvest.colors(context).surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Harvest.colors(context).border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Top Selling Produce',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  for (final entry in ranked.take(5))
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Icon(
                            Icons.eco_outlined,
                            size: 16,
                            color: Harvest.colors(context).green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Text(
                            '${entry.value} units',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Harvest.colors(context).green,
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
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final TextEditingController _search = TextEditingController();
  String _selectedFilter = 'All';

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

    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }

    final query = _search.text.toLowerCase().trim();

    final allUsers = store.accounts.where((a) {
      if (query.isNotEmpty) {
        return a.name.toLowerCase().contains(query) ||
            a.email.toLowerCase().contains(query);
      }
      return true;
    }).toList();

    final customerCount = store.accounts
        .where((a) => a.role == UserRole.customer)
        .length;
    final farmerCount = store.accounts
        .where((a) => a.role == UserRole.farmer)
        .length;
    final totalCount = store.accounts.length;

    final users = allUsers.where((a) {
      if (_selectedFilter == 'Customers') return a.role == UserRole.customer;
      if (_selectedFilter == 'Farmers') return a.role == UserRole.farmer;
      return true;
    }).toList();

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
          'Users',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Filter Tabs matching Image 1: All (1,248) | Customers (1,012) | Farmers (186)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _filterPill(
                  'All',
                  'All ($totalCount)',
                  _selectedFilter == 'All',
                  () => setState(() => _selectedFilter = 'All'),
                  palette,
                ),
                const SizedBox(width: 8),
                _filterPill(
                  'Customers',
                  'Customers ($customerCount)',
                  _selectedFilter == 'Customers',
                  () => setState(() => _selectedFilter = 'Customers'),
                  palette,
                ),
                const SizedBox(width: 8),
                _filterPill(
                  'Farmers',
                  'Farmers ($farmerCount)',
                  _selectedFilter == 'Farmers',
                  () => setState(() => _selectedFilter = 'Farmers'),
                  palette,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: palette.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.border),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, size: 20, color: palette.muted),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _search,
                    decoration: InputDecoration(
                      hintText: 'Search users by name or email...',
                      hintStyle: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 13,
                        color: palette.muted,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                if (_search.text.isNotEmpty)
                  GestureDetector(
                    onTap: () => setState(() => _search.clear()),
                    child: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: palette.muted,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (users.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  'No users match your filter.',
                  style: TextStyle(fontFamily: 'Manrope', color: palette.muted),
                ),
              ),
            ),

          for (final a in users) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: InkWell(
                onTap: () => openPage(context, UserDetailScreen(account: a)),
                borderRadius: BorderRadius.circular(20),
                child: Row(
                  children: [
                    // Avatar circle
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: a.role == UserRole.farmer
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        a.name.isNotEmpty ? a.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: a.role == UserRole.farmer
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a.name,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            a.email,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 11,
                              color: palette.muted,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  (a.role == UserRole.farmer
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFF3B82F6))
                                      .withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              a.role.label,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: a.role == UserRole.farmer
                                    ? const Color(0xFF059669)
                                    : const Color(0xFF2563EB),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status Badge & Date & 3 Dots
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2.5,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    (a.active
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444))
                                        .withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                a.active ? 'Active' : 'Inactive',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: a.active
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFFEF4444),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(
                                Icons.more_horiz_rounded,
                                size: 18,
                              ),
                              color: palette.muted,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => openPage(
                                context,
                                UserDetailScreen(account: a),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Sep 24, 2026',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: palette.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _filterPill(
    String id,
    String label,
    bool isSelected,
    VoidCallback onTap,
    HarvestPalette palette,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? palette.green : palette.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? palette.green : palette.border,
            width: 1.2,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : palette.ink,
          ),
        ),
      ),
    );
  }
}

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final account =
        store.accounts.where((a) => a.id == this.account.id).firstOrNull ??
        this.account;
    final farms = store.farms.where((f) => f.owner == account.id).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: Text(
          account.role.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Harvest.colors(context).paleLeaf,
              child: Text(
                account.name[0],
                style: Harvest.editorial(32, color: Harvest.forest),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            account.name,
            textAlign: TextAlign.center,
            style: Harvest.editorial(26),
          ),
          Text(
            account.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: Harvest.colors(context).muted),
          ),
          const SizedBox(height: 16),
          Center(
            child: StatusBadge(
              account.active ? 'Account Active' : 'Account Suspended',
              success: account.active,
              warning: !account.active,
            ),
          ),
          const SizedBox(height: 24),
          Text('ID: ${account.id}'),
          if (account.createdAt != null)
            Text('Joined: ${dateLabel(account.createdAt!)}'),
          HarvestButton(
            label: 'Edit contact details',
            onPressed: () =>
                openPage(context, ProfileEditorScreen(account: account)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Contact Information',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Phone: ${account.phone.isEmpty ? "Not provided" : account.phone}',
          ),
          const SizedBox(height: 4),
          Text(
            'Address: ${account.address.isEmpty ? "Not provided" : account.address}',
          ),
          if (farms.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Farm Information',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            for (final f in farms) ...[
              FarmerTile(farm: f),
              HarvestButton(
                label: 'Edit farm information',
                onPressed: () => openPage(context, FarmEditorScreen(farm: f)),
              ),
              const SectionHeader('Products'),
              for (final p in store.products.where((p) => p.farmId == f.id))
                InventoryRow(product: p),
            ],
          ],
          const SectionHeader('Orders in loaded pages'),
          for (final o in store.orders.where(
            (o) => account.role == UserRole.customer
                ? o.customerId == account.id
                : farms.any((f) => f.id == o.farmId),
          ))
            OrderCard(order: o),
          if (store.hasMore)
            TextButton(
              onPressed: store.loadMore,
              child: const Text('Load more records'),
            ),
          const SizedBox(height: 28),
          HarvestButton(
            label: account.active ? 'Suspend Account' : 'Reactivate Account',
            outlined: true,
            color: account.active ? Harvest.danger : Harvest.forest,
            onPressed: () async {
              final action = account.active ? 'Suspend' : 'Reactivate';
              if (await confirmAction(
                context,
                title: '$action ${account.name}?',
                message:
                    'Suspended accounts cannot use the platform or receive new orders. Historical records are retained.',
                action: action,
                isDestructive: account.active,
              )) {
                final result = await store.toggleAccount(account);
                if (context.mounted) {
                  notice(
                    context,
                    result ?? "Account status updated",
                    isError: result != null,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final TextEditingController _search = TextEditingController();
  bool _showSearch = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _editCategory(BuildContext context, {String? category}) async {
    final store = HarvestScope.of(context);
    final controller = TextEditingController(text: category);
    String? error;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheet) => StatefulBuilder(
        builder: (context, update) => SheetBody(
          children: [
            Text(
              category == null ? 'Add Category' : 'Edit Category',
              style: Harvest.editorial(24),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Category Name',
                errorText: error,
              ),
            ),
            const SizedBox(height: 20),
            HarvestButton(
              label: category == null ? 'Create Category' : 'Save Changes',
              onPressed: store.busy
                  ? null
                  : () async {
                      final result = await store.saveCategory(
                        controller.text,
                        previous: category,
                      );
                      if (!context.mounted) return;
                      if (result != null) {
                        update(() => error = result);
                        return;
                      }
                      Navigator.pop(sheet);
                    },
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }

    final query = _search.text.toLowerCase().trim();
    final categories = store.categories.where((c) {
      if (query.isNotEmpty && !c.toLowerCase().contains(query)) return false;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: const Text(
          'Market Categories',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          IconButton(
            tooltip: 'Search categories',
            icon: Icon(
              _showSearch ? Icons.close_rounded : Icons.search_rounded,
            ),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) _search.clear();
            }),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 14, left: 4),
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => _editCategory(context),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: SearchBox(
                controller: _search,
                hint: 'Search categories…',
                onChanged: (_) => setState(() {}),
              ),
            ),
          if (store.live) const DataStatusBar(),
          if (categories.isEmpty)
            const InfoNote('No categories yet. Tap + Add to begin.'),
          for (final c in categories) ...[
            Builder(
              builder: (ctx) {
                final count = store.live
                    ? store.categoryCounts[c] ?? 0
                    : store.products.where((p) => p.category == c).length;
                final (iconEmoji, bgColor) = switch (c.toLowerCase()) {
                  'fruits' => ('🍎', const Color(0xFFFEE2E2)),
                  'vegetables' => ('🥕', const Color(0xFFDCFCE7)),
                  'dairy' => ('🥛', const Color(0xFFDBEAFE)),
                  'grains' => ('🌾', const Color(0xFFFEF3C7)),
                  'herbs' => ('🌿', const Color(0xFFD1FAE5)),
                  _ => ('📦', const Color(0xFFFFEDD5)),
                };

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Harvest.colors(context).surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Harvest.colors(context).border),
                    boxShadow: Harvest.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: bgColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          iconEmoji,
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              c,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$count products',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                color: Harvest.colors(context).muted,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.edit_outlined,
                          size: 19,
                          color: Harvest.colors(context).green,
                        ),
                        onPressed: () => _editCategory(context, category: c),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          Icons.more_horiz_rounded,
                          size: 19,
                          color: Harvest.colors(context).muted,
                        ),
                        onSelected: (val) async {
                          if (val == 'edit') {
                            _editCategory(context, category: c);
                          } else if (val == 'delete') {
                            if (await confirmAction(
                              context,
                              title: 'Remove $c?',
                              message:
                                  'Only categories without assigned products can be deleted.',
                              action: 'Remove Category',
                              isDestructive: true,
                            )) {
                              final err = await store.deleteCategory(c);
                              if (context.mounted) {
                                notice(
                                  context,
                                  err ?? 'Category removed',
                                  isError: err != null,
                                );
                              }
                            }
                          }
                        },
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Text('Edit Category'),
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
                );
              },
            ),
          ],
        ],
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: 'Add New Category',
          icon: Icons.add,
          onPressed: () => _editCategory(context),
        ),
      ),
    );
  }
}
