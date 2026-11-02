part of '../../common/reports/reporting.dart';

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
