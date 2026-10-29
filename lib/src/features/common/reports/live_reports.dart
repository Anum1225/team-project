part of 'reporting.dart';

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
            else if (snapshot.data == null || snapshot.data!.isEmpty)
              const InfoNote('No report data is available yet.')
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
