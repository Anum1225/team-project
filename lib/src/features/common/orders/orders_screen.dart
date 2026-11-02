part of 'orders.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, this.initialAccountId, this.initialFarmerId});
  final String? initialAccountId, initialFarmerId;

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _search = TextEditingController();
  String _query = "";
  bool _oldest = false;
  String _sort = 'Newest first';
  late String _selected =
      widget.initialAccountId != null || widget.initialFarmerId != null
      ? 'All'
      : 'Active';

  Future<void> _showSort() async {
    var sort = _sort;
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, update) => SheetBody(
          children: [
            const PageHeading('Sort orders'),
            ChoiceRow(
              values: const [
                'Newest first',
                'Oldest first',
                'Total: low to high',
                'Total: high to low',
              ],
              selected: sort,
              onSelected: (value) => update(() => sort = value),
            ),
            const SizedBox(height: 12),
            HarvestButton(
              label: 'Apply',
              onPressed: () {
                setState(() => _sort = sort);
                Navigator.pop(sheetContext);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);

    if (store.isDemo) return const GuestAccountPrompt(title: 'Your orders');
    final allOrders = store.visibleOrders;
    final pendingCount = allOrders
        .where((o) => o.status == OrderStatus.pending)
        .length;
    final processingCount = allOrders
        .where(
          (o) =>
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.ready,
        )
        .length;
    final completedCount = allOrders
        .where((o) => o.status == OrderStatus.completed)
        .length;
    final cancelledCount = allOrders
        .where((o) => o.status == OrderStatus.cancelled)
        .length;

    final filterTabs = [
      ('All', 'All (${allOrders.length})'),
      ('Pending', 'Pending ($pendingCount)'),
      ('Processing', 'Processing ($processingCount)'),
      ('Completed', 'Completed ($completedCount)'),
      ('Cancelled', 'Cancelled ($cancelledCount)'),
    ];

    final orders = allOrders.where((o) {
      if (widget.initialAccountId != null &&
          o.customerId != widget.initialAccountId) {
        return false;
      }
      if (widget.initialFarmerId != null &&
          !store.farms.any(
            (farm) =>
                farm.id == o.farmId && farm.owner == widget.initialFarmerId,
          )) {
        return false;
      }
      if (!'${o.id} ${o.customerName} ${o.customerId} ${o.farmName} ${o.farmId}'
          .toLowerCase()
          .contains(_query.toLowerCase().trim())) {
        return false;
      }
      if (_selected == 'All') return true;
      if (_selected == 'Pending') return o.status == OrderStatus.pending;
      if (_selected == 'Processing') {
        return o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.ready;
      }
      if (_selected == 'Completed') return o.status == OrderStatus.completed;
      if (_selected == 'Cancelled') return o.status == OrderStatus.cancelled;
      if (_selected == 'Active') return o.status.active;
      if (_selected == 'Past') return !o.status.active;
      return o.status.label == _selected;
    }).toList();

    if (store.role != UserRole.customer) {
      orders.sort(
        (a, b) => switch (_sort) {
          'Oldest first' => a.date.compareTo(b.date),
          'Total: low to high' => a.total.compareTo(b.total),
          'Total: high to low' => b.total.compareTo(a.total),
          _ => b.date.compareTo(a.date),
        },
      );
    } else if (_oldest) {
      orders.sort((a, b) => a.date.compareTo(b.date));
    }

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: store.role == UserRole.customer && !Navigator.canPop(context)
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                onPressed: () => Navigator.maybePop(context),
              ),
        title: Text(
          'Orders',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            color: palette.ink,
          ),
        ),
        actions: [
          IconButton(
            tooltip: store.role == UserRole.customer
                ? (_oldest ? 'Sorted: Oldest first' : 'Sorted: Newest first')
                : 'Sort orders',
            icon: Icon(
              Icons.tune_rounded,
              color:
                  (store.role == UserRole.customer
                      ? _oldest
                      : _sort != 'Newest first')
                  ? palette.green
                  : null,
            ),
            onPressed: store.role != UserRole.customer
                ? _showSort
                : () => setState(() => _oldest = !_oldest),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          // Filter Tabs matching Image 1 Screen 5 & Image 2 Screen 3
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in filterTabs)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => setState(() => _selected = tab.$1),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _selected == tab.$1
                              ? palette.green
                              : palette.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _selected == tab.$1
                                ? palette.green
                                : palette.border,
                            width: 1.2,
                          ),
                        ),
                        child: Text(
                          tab.$2,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: _selected == tab.$1
                                ? FontWeight.w800
                                : FontWeight.w600,
                            color: _selected == tab.$1
                                ? Colors.white
                                : palette.ink,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Search Box
          if (store.role == UserRole.admin)
            SearchBox(
              controller: _search,
              hint: 'Search order #, customer or farm…',
              managementStyle: true,
              onChanged: (value) => setState(() => _query = value),
            )
          else
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
                      decoration: InputDecoration(
                        hintText: 'Search order #, customer or farm…',
                        hintStyle: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                          color: palette.muted,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          if (orders.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Column(
                  children: [
                    Icon(
                      Icons.receipt_long_outlined,
                      size: 48,
                      color: palette.muted,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No orders in this view',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: palette.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Try changing your filter or search query.',
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
            for (final o in orders) OrderCard(order: o),
          if (store.hasMore)
            TextButton(
              onPressed: store.loadMore,
              child: const Text('Load more orders'),
            ),
        ],
      ),
    );
  }
}
