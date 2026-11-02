import 'package:flutter/material.dart';

import 'components.dart';
import 'models.dart';
import 'operations.dart';
import 'orders.dart';
import 'theme.dart';

class AdminDashboard extends StatelessWidget {
  const AdminDashboard({
    super.key,
    required this.onProducts,
    required this.onOrders,
  });
  final VoidCallback onProducts, onOrders;
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (!store.authenticated || store.role != UserRole.admin) {
      return const Center(child: Text('Administrator access required.'));
    }
    final r = store.report;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          'Platform Overview',
          subtitle: 'Marketplace totals from stored records.',
        ),
        if (r == null)
          const InfoNote(
            'Report totals are loading. Use refresh to retry if needed.',
          )
        else ...[
          for (final row in [
            [
              ('Total Customers', '${r['customers']}'),
              ('Total Farmers', '${r['farmers']}'),
            ],
            [
              ('Products', '${r['products']}'),
              ('Categories', '${r['categories']}'),
            ],
            [
              ('Total Orders', '${r['totalOrders']}'),
              ('Active Farmers', '${r['activeFarmers']}'),
            ],
          ])
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  for (final cell in row)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: MetricCard(
                          label: cell.$1,
                          value: cell.$2,
                          icon: Icons.analytics_outlined,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          MetricCard(
            label: 'Simulated order value · all statuses',
            value: money((r['orderValue'] as num).toInt()),
            icon: Icons.receipt_long_outlined,
            dark: true,
          ),
          const SizedBox(height: 12),
          MetricCard(
            label: 'Completed simulated order value',
            value: money((r['completedValue'] as num).toInt()),
            icon: Icons.task_alt,
          ),
          const SizedBox(height: 12),
          Text('Out of stock: ${r['outOfStock']}'),
          const SectionHeader('Orders by status'),
          for (final s in OrderStatus.values)
            ListTile(
              title: Text(s.label),
              trailing: Text('${(r['statuses'] as Map)[s.name]}'),
            ),
        ],
        const InfoNote(
          'Order values are simulated sales, not payments received.',
        ),
        const SizedBox(height: 12),
        HarvestButton(
          label: 'Platform reports',
          onPressed: () => openPage(context, const LiveReports()),
        ),
        const SizedBox(height: 12),
        HarvestButton(
          label: 'Manage catalog',
          onPressed: onProducts,
          outlined: true,
        ),
        SectionHeader(
          'Recent orders',
          action: 'All orders',
          onAction: onOrders,
        ),
        if (store.orders.isEmpty) const InfoNote('No orders available.'),
        for (final o in store.visibleOrders.take(5)) OrderCard(order: o),
        const SectionHeader('Low stock in loaded catalog'),
        for (final p in store.products.where((p) => p.stock <= 5).take(5))
          InventoryRow(product: p),
      ],
    );
  }
}

class LiveReports extends StatefulWidget {
  const LiveReports({super.key});
  @override
  State<LiveReports> createState() => _LiveReportsState();
}

class _LiveReportsState extends State<LiveReports> {
  int days = 7;
  Future<Map<String, dynamic>>? result;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = HarvestScope.of(context);
    if (store.canManageShop) result ??= store.fetchReport(days);
  }

  void reload([int? value]) {
    setState(() {
      days = value ?? days;
      result = HarvestScope.of(context).fetchReport(days);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!HarvestScope.of(context).canManageShop) {
      return const Center(
        child: Text('Farmer or administrator access required.'),
      );
    }
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Platform reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh reports',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: result,
        builder: (context, snapshot) {
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PageHeading(
                'Sales & Harvests',
                subtitle: 'Simulated order values · dates grouped in UTC',
              ),
              ChoiceRow(
                values: const ['Day', 'Week', 'Month'],
                selected: days == 1
                    ? 'Day'
                    : days == 7
                    ? 'Week'
                    : 'Month',
                onSelected: (v) => reload(
                  v == 'Day'
                      ? 1
                      : v == 'Week'
                      ? 7
                      : 30,
                ),
              ),
              const SizedBox(height: 16),
              if (snapshot.connectionState != ConnectionState.done)
                const Center(child: CircularProgressIndicator())
              else if (snapshot.hasError)
                InfoNote(
                  'Reports could not be loaded. Check your connection and refresh.',
                  error: true,
                )
              else if (snapshot.data case final r?) ...[
                MetricCard(
                  label: 'Total orders',
                  value: '${r['totalOrders']}',
                  icon: Icons.receipt_long_outlined,
                ),
                const SizedBox(height: 12),
                MetricCard(
                  label: 'Simulated order value · all statuses',
                  value: money((r['orderValue'] as num).toInt()),
                  icon: Icons.analytics_outlined,
                ),
                const SizedBox(height: 12),
                MetricCard(
                  label: 'Completed simulated order value',
                  value: money((r['completedValue'] as num).toInt()),
                  icon: Icons.task_alt,
                ),
                const SizedBox(height: 20),
                OrderValueChart(
                  values: (r['trend'] as List)
                      .map((v) => (v as num).toDouble())
                      .toList(),
                ),
                const SectionHeader('Orders by status'),
                for (final s in OrderStatus.values)
                  ListTile(
                    title: Text(s.label),
                    trailing: Text('${(r['statuses'] as Map)[s.name]}'),
                  ),
                const SectionHeader('Most active farmers · orders received'),
                if ((r['farmers'] as List).isEmpty)
                  const InfoNote('No farmer activity in this period.'),
                for (final f in r['farmers'] as List)
                  ListTile(
                    title: Text('${f['name']}'),
                    subtitle: Text(
                      '${f['completed']} completed · ${money((f['value'] as num).toInt())} simulated value',
                    ),
                    trailing: Text('${f['orders']} orders'),
                  ),
                const SectionHeader('Market summaries'),
                if ((r['markets'] as List).isEmpty)
                  const InfoNote('No market orders in this period.'),
                for (final m in r['markets'] as List)
                  ListTile(
                    title: Text('${m['name']}'),
                    subtitle: Text(
                      '${m['orders']} orders · ${m['completed']} completed',
                    ),
                    trailing: Text(money((m['value'] as num).toInt())),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class OrderValueChart extends StatelessWidget {
  const OrderValueChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    final max = values.fold<double>(0, (a, b) => a > b ? a : b);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily simulated order value',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        if (max == 0)
          const InfoNote('No order value recorded in this period.')
        else
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < values.length; i++)
                  Expanded(
                    child: Tooltip(
                      message: 'Day ${i + 1}: ${money(values[i].toInt())}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: Container(
                          height: 130 * values[i] / max + 1,
                          decoration: BoxDecoration(
                            color: Harvest.forest,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 6),
        const Text(
          'Oldest → newest · UTC calendar days',
          style: TextStyle(fontSize: 11, color: Harvest.muted),
        ),
      ],
    );
  }
}
