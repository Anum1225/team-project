import 'market_directory.dart';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'components.dart';
import 'models.dart';
import 'theme.dart';
import 'animated_chart.dart';
import 'theme_reveal.dart';

int _reportNumber(Object? value) => value is num ? value.toInt() : 0;

String _reportCount(Object? value) =>
    value == null ? '—' : '${_reportNumber(value)}';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({
    super.key,
    required this.onProducts,
    required this.onOrders,
  });
  final VoidCallback onProducts, onOrders;

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String _timeframe = 'This Month';
  String _chartRange = '7 Days';

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final report = store.report ?? const <String, dynamic>{};
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 36),
          children: [
            // 1. Top Brand Navigation Header
            HarvestHubBrandHeader(
              marketName: 'Admin Control Center',
              onNotificationTap: widget.onOrders,
              unreadNotifications: false,
            ),

            // 2. Greeting Header matching reference Image 1
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Welcome back,\n${store.account.name}.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : palette.forest,
                            height: 1.15,
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                      // Timeframe Selector Pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: palette.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: palette.border, width: 1.2),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _timeframe,
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'This Week',
                                child: Text(
                                  '📅 This Week',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'This Month',
                                child: Text(
                                  '📅 This Month',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'All Time',
                                child: Text(
                                  '📅 All Time',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _timeframe = v);
                              store.loadReport(switch (v) {
                                'This Week' => 7,
                                'This Month' => 30,
                                _ => 36500,
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Manage your platform, farmers, products and grow stronger communities.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: palette.muted,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),

            // 3. 2x2 Metric Cards matching Image 1
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - 12) / 2;
                final metrics = [
                  _AdminMetricCard(
                    title: 'Total Users',
                    value: _reportCount(report['users']),
                    pillText: 'Live',
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                  _AdminMetricCard(
                    title: 'Farmers',
                    value: _reportCount(report['farmerCount']),
                    pillText: 'Live',
                    icon: Icons.eco_rounded,
                    iconColor: const Color(0xFF059669),
                  ),
                  _AdminMetricCard(
                    title: 'Customers',
                    value: _reportCount(report['customers']),
                    pillText: 'Live',
                    icon: Icons.shopping_basket_rounded,
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _AdminMetricCard(
                    title: 'Products',
                    value: _reportCount(report['products']),
                    pillText: 'Live',
                    icon: Icons.inventory_2_rounded,
                    iconColor: const Color(0xFF8B5CF6),
                  ),
                ];

                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: metrics
                      .map((m) => SizedBox(width: cardWidth, child: m))
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 14),

            // 4. Dedicated Total Revenue Card with mini sparkline
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: palette.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16A34A).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: Color(0xFF16A34A),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Revenue',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.muted,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          runSpacing: 4,
                          children: [
                            Text(
                              money(_reportNumber(report['completedValue'])),
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: palette.ink,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Completed orders',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Sparkline mini preview
                  SizedBox(
                    width: 64,
                    height: 38,
                    child: CustomPaint(
                      painter: _MiniSparklinePainter(
                        color: const Color(0xFF16A34A),
                        values: ((report['trend'] as List?) ?? const [])
                            .map((v) => (v as num).toDouble())
                            .toList()
                            .take(7)
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 5. Orders Overview Chart Card matching Image 1
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 20,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Orders by status',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: palette.canvas,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: palette.border),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _chartRange,
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 16,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: '7 Days',
                                child: Text(
                                  '7 Days',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              DropdownMenuItem(
                                value: '30 Days',
                                child: Text(
                                  '30 Days',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                            onChanged: (v) {
                              if (v == null) return;
                              setState(() => _chartRange = v);
                              store.loadReport(v == '7 Days' ? 7 : 30);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const SizedBox(height: 16),
                  if (report['statuses'] is Map &&
                      _reportNumber(report['totalOrders']) > 0)
                    AnimatedHarvestChart(
                      values: OrderStatus.values
                          .map(
                            (s) => _reportNumber(
                              (report['statuses'] as Map)[s.name],
                            ).toDouble(),
                          )
                          .toList(),
                      initialMode: ChartMode.spline,
                    )
                  else
                    const InfoNote('No orders in this period yet.'),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 6. Top Selling Products matching Image 1
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  size: 20,
                  color: Color(0xFFEA580C),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Most active farmers',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: widget.onProducts,
                  child: Text(
                    'See All',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: palette.green,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if ((report['farmers'] as List? ?? const []).isEmpty)
              const InfoNote('No farmer orders in this period yet.')
            else
              for (final raw in (report['farmers'] as List).take(3))
                Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: palette.border),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: palette.paleLeaf,
                      child: Icon(Icons.eco_rounded, color: palette.green),
                    ),
                    title: Text(
                      '${raw['name']}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${raw['completed']} completed · ${money(_reportNumber(raw['value']))}',
                    ),
                    trailing: Text(
                      '${raw['orders']} orders',
                      style: TextStyle(
                        color: palette.green,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 14),

            // Quick Hub Buttons for Analytics, Reviews, Reports, Settings
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        openPage(context, const AdminAnalyticsScreen()),
                    icon: const Icon(Icons.analytics_outlined, size: 15),
                    label: const Text(
                      'Analytics',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openPage(context, const ReviewsScreen()),
                    icon: const Icon(Icons.feedback_outlined, size: 15),
                    label: const Text(
                      'Feedback',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        openPage(context, const AdminReportsScreen()),
                    icon: const Icon(Icons.assessment_outlined, size: 15),
                    label: const Text(
                      'Reports',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: palette.border),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMetricCard extends StatelessWidget {
  const _AdminMetricCard({
    required this.title,
    required this.value,
    required this.pillText,
    required this.icon,
    required this.iconColor,
  });

  final String title, value, pillText;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: palette.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 15, color: iconColor),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              pillText,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Color(0xFF10B981),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class LiveReports extends StatefulWidget {
  const LiveReports({super.key, this.title = 'Platform reports'});
  final String title;
  @override
  State<LiveReports> createState() => _LiveReportsState();
}

class _LiveReportsState extends State<LiveReports> {
  int days = 7;
  Future<Map<String, dynamic>>? result;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    result ??= HarvestScope.of(context).fetchReport(days);
  }

  void reload([int? value]) {
    setState(() {
      days = value ?? days;
      result = HarvestScope.of(context).fetchReport(days);
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
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
              const InfoNote(
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

class OrderValueChart extends StatelessWidget {
  const OrderValueChart({super.key, required this.values});
  final List<double> values;
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily simulated order value',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        AnimatedHarvestChart(values: values),
        const SizedBox(height: 6),
        Text(
          'Oldest → newest · UTC calendar days',
          style: TextStyle(fontSize: 11, color: Harvest.colors(context).muted),
        ),
      ],
    );
  }
}

class _MiniSparklinePainter extends CustomPainter {
  const _MiniSparklinePainter({required this.color, required this.values});
  final Color color;
  final List<double> values;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y =
          size.height - ((values[i] - minVal) / range) * (size.height - 6) - 3;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _MiniSparklinePainter oldDelegate) => false;
}

class AdminAnalyticsScreen extends StatelessWidget {
  const AdminAnalyticsScreen({super.key});
  @override
  Widget build(BuildContext context) => const LiveReports(title: 'Analytics');
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: const Text('Customer feedback'),
        actions: [
          IconButton(
            tooltip: 'Refresh feedback',
            onPressed: store.refresh,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: store.feedback.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(28),
                child: InfoNote('No customer feedback has been received yet.'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(18),
              itemCount: store.feedback.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = store.feedback[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: palette.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: palette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: palette.paleLeaf,
                            child: Icon(
                              Icons.person_outline_rounded,
                              color: palette.green,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                Text(
                                  dateLabel(item.date),
                                  style: TextStyle(
                                    color: palette.muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (!item.read)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: palette.paleLeaf,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'New',
                                style: TextStyle(
                                  color: palette.green,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item.message,
                        style: TextStyle(color: palette.ink, height: 1.45),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class AdminReportsScreen extends StatelessWidget {
  const AdminReportsScreen({super.key});
  @override
  Widget build(BuildContext context) => const LiveReports(title: 'Reports');
}

class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({
    super.key,
    required this.onUsers,
    required this.onCategories,
  });

  final VoidCallback onUsers;
  final VoidCallback onCategories;

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 30),
        children: [
          const SectionHeader('Appearance'),
          SwitchListTile.adaptive(
            value: dark,
            title: Text(dark ? 'Dark appearance' : 'Light appearance'),
            subtitle: const Text('Use the theme that is easiest to read.'),
            secondary: Icon(
              dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: palette.green,
            ),
            onChanged: (_) => ThemeReveal.toggle(context),
          ),
          const SizedBox(height: 14),
          const SectionHeader('Platform management'),
          _settingsAction(
            context,
            Icons.storefront_outlined,
            'Farmers markets',
            'Publish locations, map positions and opening hours',
            () => openPage(context, const MarketDirectory()),
          ),
          _settingsAction(
            context,
            Icons.edit_note_outlined,
            'Public content',
            'Maintain About and support contact details',
            () => openPage(context, const PublicContentEditor()),
          ),
          _settingsAction(
            context,
            Icons.people_alt_outlined,
            'Accounts and access',
            'Review and suspend customer or farmer accounts',
            onUsers,
          ),
          _settingsAction(
            context,
            Icons.category_outlined,
            'Product categories',
            'Maintain the live product catalog categories',
            onCategories,
          ),
          _settingsAction(
            context,
            Icons.feedback_outlined,
            'Customer feedback',
            'Read messages submitted from customer support',
            () => openPage(context, const ReviewsScreen()),
          ),
          _settingsAction(
            context,
            Icons.analytics_outlined,
            'Platform reports',
            'Order totals, completed value and active farmers',
            () =>
                openPage(context, const LiveReports(title: 'Platform reports')),
          ),
          const SizedBox(height: 14),
          const InfoNote(
            'Checkout records simulated orders. No payment provider is configured.',
          ),
        ],
      ),
    );
  }

  Widget _settingsAction(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) {
    final palette = Harvest.colors(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 9),
      child: ListTile(
        leading: Icon(icon, color: palette.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right_rounded),
        onTap: action,
      ),
    );
  }
}
