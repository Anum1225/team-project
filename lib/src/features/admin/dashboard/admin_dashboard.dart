part of '../../common/reports/reporting.dart';

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
    final metricsLoading =
        store.reportLoading ||
        (store.live && store.report == null && store.error == null);
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
              notificationButton: InboxIndicator(
                onOpen: () async {
                  await openPage(context, const NotificationsScreen());
                },
              ),
              unreadNotifications: false,
              onProfileTap: () => openPage(
                context,
                ProfileScreen(onExit: () => Navigator.maybePop(context)),
              ),
            ),

            // 2. Greeting Header matching reference Image 1
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                gradient: LinearGradient(
                  colors: [
                    palette.green.withValues(alpha: .13),
                    palette.surface,
                  ],
                ),
                border: Border.all(color: palette.green.withValues(alpha: .16)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,\n${store.account.name}.',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : palette.forest,
                          height: 1.15,
                          letterSpacing: -0.4,
                        ),
                      ),
                      const SizedBox(height: 14),
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
                    loading: metricsLoading,
                    value: _reportCount(report['users']),
                    pillText: 'Live',
                    icon: Icons.people_alt_rounded,
                    iconColor: const Color(0xFF10B981),
                  ),
                  _AdminMetricCard(
                    title: 'Farmers',
                    loading: metricsLoading,
                    value: _reportCount(report['farmerCount']),
                    pillText: 'Live',
                    icon: Icons.eco_rounded,
                    iconColor: const Color(0xFF059669),
                  ),
                  _AdminMetricCard(
                    title: 'Customers',
                    loading: metricsLoading,
                    value: _reportCount(report['customers']),
                    pillText: 'Live',
                    icon: Icons.shopping_basket_rounded,
                    iconColor: const Color(0xFF2563EB),
                  ),
                  _AdminMetricCard(
                    title: 'Products',
                    loading: metricsLoading,
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
                            if (metricsLoading)
                              const _MetricLoading(width: 110)
                            else
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
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.14),
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
