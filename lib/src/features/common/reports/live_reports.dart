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
  bool exporting = false;
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

  Future<void> downloadPdf() async {
    if (exporting) return;
    setState(() => exporting = true);
    try {
      final data = await result;
      if (data == null || data.isEmpty) {
        throw StateError('No report data available.');
      }
      if (!mounted) return;
      final store = HarvestScope.of(context);
      final document = pw.Document();
      final statuses = data['statuses'] as Map? ?? const {};
      final generated = DateTime.now();
      document.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (_) => [
            pw.Header(
              level: 0,
              child: pw.Text(
                'HarvestHub ${store.role == UserRole.admin ? 'Platform' : 'Farm'} Report',
              ),
            ),
            if (store.role == UserRole.farmer)
              pw.Text('Farm: ${store.ownFarm.name}'),
            pw.Text('Period: Last $days days'),
            pw.Text(
              'Generated: ${generated.day}/${generated.month}/${generated.year}',
            ),
            pw.SizedBox(height: 16),
            pw.Text('Total orders: ${data['totalOrders'] ?? 0}'),
            pw.Text(
              'Order value: ${money((data['orderValue'] as num? ?? 0).toInt())}',
            ),
            pw.Text(
              'Completed order value: ${money((data['completedValue'] as num? ?? 0).toInt())}',
            ),
            pw.Text('Products: ${data['products'] ?? 0}'),
            pw.Text('Out of stock: ${data['outOfStock'] ?? 0}'),
            pw.SizedBox(height: 16),
            pw.Header(level: 1, child: pw.Text('Orders by status')),
            for (final status in OrderStatus.values)
              pw.Text('${status.label}: ${statuses[status.name] ?? 0}'),
          ],
        ),
      );
      await Printing.layoutPdf(
        name:
            'HarvestHub-${store.role == UserRole.admin ? 'platform' : 'farm'}-report-${generated.year}-${generated.month}-${generated.day}.pdf',
        onLayout: (_) => document.save(),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not download the PDF report.')),
        );
      }
    } finally {
      if (mounted) setState(() => exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
      actions: [
        if (HarvestScope.of(context).role != UserRole.customer)
          IconButton(
            tooltip: 'Download PDF',
            onPressed: exporting ? null : downloadPdf,
            icon: exporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf_outlined),
          ),
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
