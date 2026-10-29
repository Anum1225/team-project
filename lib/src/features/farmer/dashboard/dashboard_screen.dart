part of '../../common/management/operations.dart';

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
                notificationButton: InboxIndicator(
                  onOpen: () async {
                    await openPage(context, const NotificationsScreen());
                  },
                ),
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
                        Expanded(
                          child: Text(
                            'YOUR HARVEST, IN ONE PLACE',
                            style: TextStyle(
                              color: Color(0xFFD8F1D7),
                              fontSize: 10,
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      farm.description.trim().isNotEmpty ? farm.description : 'Keep your farm profile and fresh stock up to date.',
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
