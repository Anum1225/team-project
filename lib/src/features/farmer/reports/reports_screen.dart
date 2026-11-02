part of '../../common/management/operations.dart';

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
                                backgroundColor: Harvest.colors(context)
                                    .paleLeaf,
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
