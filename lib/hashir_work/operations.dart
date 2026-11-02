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
import 'theme.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onProducts,
    required this.onOrders,
  });

  final VoidCallback onProducts, onOrders;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!store.canManageShop) {
      return const Center(
        child: Text('Farmer or administrator access required.'),
      );
    }
    final admin = store.role == UserRole.admin;
    if (store.live && admin) {
      return AdminDashboard(onProducts: onProducts, onOrders: onOrders);
    }
    final products = store.visibleProducts;
    final orders = store.visibleOrders;
    final attention = orders
        .where((o) => o.status == OrderStatus.pending)
        .toList();
    final low = products.where((p) => p.stock <= 5).toList();
    final today = DateTime.now();
    final daily = orders
        .where(
          (o) =>
              o.date.year == today.year &&
              o.date.month == today.month &&
              o.date.day == today.day,
        )
        .length;

    return Scaffold(
      backgroundColor: Harvest.cream,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Row(
            children: [
              const SeedMark(size: 26),
              const SizedBox(width: 8),
              Eyebrow(admin ? 'HarvestHub Platform Hub' : 'Grower Operations'),
              const Spacer(),
              IconButton(
                tooltip: 'View reports',
                onPressed: () => openPage(
                  context,
                  const HarvestPage(
                    title: 'Sales & Inventory Reports',
                    child: ReportsScreen(),
                  ),
                ),
                icon: const Icon(Icons.bar_chart_outlined, size: 22),
              ),
            ],
          ),
          PageHeading(
            admin
                ? 'Platform Overview'
                : 'Good growing,\n${store.account.name.split(' ').first}.',
            subtitle: admin
                ? 'Live marketplace metrics, vendor verifications & order volume.'
                : 'Here is what is happening at ${store.ownFarm.name} today.',
          ),

          // Primary Metric Cards
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: admin ? 'Total Customers' : "Today's Orders",
                  value:
                      '${admin ? store.accounts.where((a) => a.role == UserRole.customer).length : daily}',
                  icon: admin
                      ? Icons.people_outline
                      : Icons.shopping_basket_outlined,
                  dark: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: admin ? 'Active Farmers' : 'Listed Products',
                  value: '${admin ? store.farms.length : products.length}',
                  icon: admin
                      ? Icons.storefront_outlined
                      : Icons.inventory_2_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: MetricCard(
                  label: admin ? 'Catalog Items' : 'Low Stock Items',
                  value: '${admin ? products.length : low.length}',
                  icon: Icons.warning_amber_rounded,
                  subtitle: admin
                      ? null
                      : (low.isEmpty
                            ? 'All well-stocked'
                            : 'Needs replenishment'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: MetricCard(
                  label: 'Active Orders',
                  value: '${orders.where((o) => o.status.active).length}',
                  icon: Icons.receipt_long_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Animated Growth Area Chart for Admin & Grower Performance
          GrowthAreaChart(
            title: admin ? 'Platform Volume Growth' : 'Farm Harvest Yield',
            period: 'Weekly',
          ),
          const SizedBox(height: 20),

          // Primary Quick Action
          HarvestButton(
            label: 'Add Harvest Product',
            icon: Icons.add,
            onPressed: () => openPage(context, const ProductEditorScreen()),
          ),
          const SizedBox(height: 12),

          // Orders needing attention queue
          SectionHeader(
            'Orders Needing Attention (${attention.length})',
            action: 'All orders',
            onAction: onOrders,
          ),
          if (attention.isEmpty)
            const InfoNote(
              'All caught up! New orders placed by customers will appear here immediately.',
            )
          else
            for (final o in attention.take(3)) OrderCard(order: o),

          // Inventory / Stock alert section
          SectionHeader(
            'Inventory & Restock Watch',
            action: 'Manage inventory',
            onAction: onProducts,
          ),
          if (low.isEmpty)
            const InfoNote('All farm products have healthy stock levels.')
          else
            for (final p in low.take(4)) InventoryRow(product: p),

          if (admin) ...[
            const SectionHeader('Recent Registered Users'),
            for (final person
                in store.accounts
                    .where((a) => a.role != UserRole.admin)
                    .take(4))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Harvest.border),
                  ),
                  child: MenuRow(
                    title: person.name,
                    subtitle: '${person.email} · ${person.role.label}',
                    icon: person.role == UserRole.farmer
                        ? Icons.eco_outlined
                        : Icons.person_outline,
                    onTap: () =>
                        openPage(context, UserDetailScreen(account: person)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
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

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!store.canManageShop) {
      return const Center(
        child: Text('Farmer or administrator access required.'),
      );
    }
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

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          admin ? 'Catalog Management' : 'Farm Stand Inventory',
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        actions: [
          if (admin)
            IconButton(
              tooltip: 'Categories',
              onPressed: () => openPage(context, const CategoriesScreen()),
              icon: const Icon(Icons.category_outlined),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              children: [
                SearchBox(
                  controller: _search,
                  hint: 'Search products by name…',
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                ChoiceRow(
                  values: const ['All', 'Active', 'Low stock', 'Out of stock'],
                  selected: _filter,
                  onSelected: (v) => setState(() => _filter = v),
                ),
                if (admin) ...[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Filter by Category',
                    ),
                    items: ['All', ...store.categories]
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      '${products.length} products listed',
                      style: const TextStyle(
                        color: Harvest.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (products.any((p) => p.stock == 0))
                      const Text(
                        'Zero-stock items cannot be ordered',
                        style: TextStyle(
                          color: Harvest.danger,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  EmptyState(
                    title: 'No products in this view',
                    message: 'Add your first harvest item or change your search filter.',
                    icon: Icons.inventory_2_outlined,
                  )
                else
                  for (final p in products) InventoryRow(product: p),
              ],
            ),
          ),
          BottomAction(
            child: HarvestButton(
              label: 'Add Harvest Product',
              icon: Icons.add,
              onPressed: () => openPage(context, const ProductEditorScreen()),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Harvest.border),
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
                Photo(
                  p.image,
                  bytes: p.photo,
                  width: 68,
                  height: 68,
                  radius: 12,
                  label: p.name,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${money(p.price)} / ${p.unit} · ${p.category}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Harvest.muted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      StatusBadge(
                        p.stock == 0
                            ? 'Out of stock'
                            : p.stock <= 5
                            ? 'Low stock · ${p.stock} ${p.unit}'
                            : '${p.stock} ${p.unit} available',
                        warning: p.stock <= 5,
                        success: p.stock > 5,
                        icon: p.stock == 0
                            ? Icons.remove_circle_outline
                            : Icons.inventory_2_outlined,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit product',
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: Harvest.forest,
                  ),
                  onPressed: () =>
                      openPage(context, ProductEditorScreen(product: p)),
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
    _price.text = p == null ? '' : (p.price / 100).toStringAsFixed(2);
    _stock.text = p?.stock.toString() ?? '';
    _description.text = p?.description ?? '';
    _unit.text = p?.unit ?? 'kg';
    _category = p?.category ?? store.categories.firstOrNull;
    _farmId =
        p?.farmId ??
        (store.role == UserRole.farmer
            ? store.ownFarm.id
            : store.farms.firstOrNull?.id);
    _image = p?.image ?? '';
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
      unit: _unit.text.trim(),
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
    if (!store.canManageShop) {
      return const Center(
        child: Text('Farmer or administrator access required.'),
      );
    }
    final p = widget.product;

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          p == null ? 'Add Harvest Product' : 'Edit Product',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        actions: [
          if (p != null)
            IconButton(
              tooltip: 'Delete product',
              onPressed: () async {
                if (await confirmAction(
                  context,
                  title: 'Remove this product?',
                  message: 'This will remove it from customer catalogs and shopping baskets.',
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
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
          children: [
            const Eyebrow('Product Presentation'),
            const SizedBox(height: 12),
            Photo(
              _image,
              bytes: _photo,
              height: 200,
              width: double.infinity,
              radius: 20,
              label: 'Product photo preview',
            ),
            const SizedBox(height: 12),
            HarvestButton(
              label: _picking ? 'Opening gallery…' : 'Choose / Upload Photo',
              outlined: true,
              icon: Icons.add_photo_alternate_outlined,
              onPressed: _picking ? null : _pickImage,
            ),
            const SizedBox(height: 6),
            const Text(
              'Supports PNG and JPG images up to 8MB',
              style: TextStyle(color: Harvest.muted, fontSize: 11),
            ),
            const SizedBox(height: 22),

            HarvestField(controller: _name, label: 'Product Name'),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              isExpanded: true,
              items: store.categories
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v),
              validator: (v) => v == null ? 'Choose a category.' : null,
            ),
            if (store.role == UserRole.admin) ...[
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _farmId,
                decoration: const InputDecoration(labelText: 'Farm Origin'),
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
            HarvestField(
              controller: _description,
              label: 'Description & Freshness Notes',
              lines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: HarvestField(
                    controller: _price,
                    label: 'Price in Rs',
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
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: HarvestField(
                    controller: _unit,
                    label: 'Unit (e.g. kg, 250 g)',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            HarvestField(
              controller: _stock,
              label: 'Available Stock Quantity',
              keyboard: TextInputType.number,
              validator: (v) =>
                  v == null || int.tryParse(v) == null || int.parse(v) < 0
                  ? 'Enter 0 or positive quantity'
                  : null,
            ),
            const SizedBox(height: 16),
            const InfoNote(
              'Stock Zero Rule: Setting available stock to 0 immediately flags the product as Sold Out and prevents customers from adding it to baskets.',
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              InfoNote(_error!, error: true),
            ],
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: p == null ? 'Add Product to Stand' : 'Save Changes',
          icon: Icons.check,
          onPressed: _picking || store.busy ? null : _save,
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
    if (!store.canManageShop) {
      return const Center(
        child: Text('Farmer or administrator access required.'),
      );
    }
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
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
            style: const TextStyle(fontSize: 12, color: Harvest.muted),
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
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Harvest.border),
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
                                      color: Harvest.muted,
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
                                backgroundColor: Harvest.sage,
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
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Harvest.border),
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
                          const Icon(
                            Icons.eco_outlined,
                            size: 16,
                            color: Harvest.forest,
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
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Harvest.forest,
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
  String _selectedRole = 'Customers';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!store.authenticated || store.role != UserRole.admin) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final role = _selectedRole == 'Customers'
        ? UserRole.customer
        : UserRole.farmer;
    final query = _search.text.toLowerCase().trim();

    final users = store.accounts.where((a) {
      if (a.role != role) return false;
      if (query.isNotEmpty) {
        return a.name.toLowerCase().contains(query) ||
            a.email.toLowerCase().contains(query) ||
            store.farms.any(
              (f) =>
                  f.owner == a.id &&
                  '${f.name} ${f.market}'.toLowerCase().contains(query),
            );
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Community Directory',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeading(
            'Users & Farmers',
            eyebrow: 'Admin Portal',
            subtitle: 'Manage community accounts and operational statuses.',
          ),
          SearchBox(
            controller: _search,
            hint: 'Search by user name or email…',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 14),
          ChoiceRow(
            values: const ['Customers', 'Farmers'],
            selected: _selectedRole,
            onSelected: (v) => setState(() => _selectedRole = v),
          ),
          const SizedBox(height: 18),
          if (users.isEmpty) const InfoNote('No users match this search.'),
          for (final a in users)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Harvest.border),
                boxShadow: Harvest.cardShadow,
              ),
              child: Material(
                color: Colors.transparent,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Harvest.sage,
                    child: Text(
                      a.name[0],
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Harvest.forest,
                      ),
                    ),
                  ),
                  title: Text(
                    a.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${a.email} · ${a.role.label}',
                    style: const TextStyle(fontSize: 12, color: Harvest.muted),
                  ),
                  trailing: StatusBadge(
                    a.active ? 'Active' : 'Suspended',
                    success: a.active,
                    warning: !a.active,
                  ),
                  onTap: () => openPage(context, UserDetailScreen(account: a)),
                ),
              ),
            ),
        ],
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
    if (!store.authenticated || store.role != UserRole.admin) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final account =
        store.accounts.where((a) => a.id == this.account.id).firstOrNull ??
        this.account;
    final farms = store.farms.where((f) => f.owner == account.id).toList();

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
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
              backgroundColor: Harvest.sage,
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
            style: const TextStyle(color: Harvest.muted),
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
                message: 'Suspended accounts cannot use the platform or receive new orders. Historical records are retained.',
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

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

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
    if (!store.authenticated || store.role != UserRole.admin) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }

    return Scaffold(
      backgroundColor: Harvest.cream,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Categories',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const PageHeading(
            'Market Categories',
            eyebrow: 'Catalog Structure',
            subtitle: 'Organize produce into intuitive shopping sections.',
          ),
          if (store.live) const DataStatusBar(),
          if (store.categories.isEmpty)
            const InfoNote('No categories yet. Add a category to begin.'),
          for (final c in store.categories.toList()) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Harvest.border),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.category_outlined,
                  color: Harvest.forest,
                ),
                title: Text(
                  c,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${store.live ? store.categoryCounts[c] ?? 0 : store.products.where((p) => p.category == c).length} products listed',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _editCategory(context, category: c),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Harvest.danger,
                      ),
                      onPressed: () async {
                        if (await confirmAction(
                          context,
                          title: 'Remove $c?',
                          message: 'Only categories without assigned products can be deleted.',
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
                      },
                    ),
                  ],
                ),
              ),
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
