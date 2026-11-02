import 'package:flutter/material.dart';

import '../components.dart';
import '../theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final notices = store.customerNotices;
    return HarvestPage(
      title: 'Notifications',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'A little news from the farm',
            subtitle: 'Your order and pickup updates.',
          ),
          const InfoNote(
            'Order-status and restock alerts for saved products and followed farms. Enable notifications on your phone to receive them in the background.',
          ),
          if (notices.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text('All quiet for now.'),
            ),
          if (notices.isNotEmpty)
            TextButton(
              onPressed: store.busy
                  ? null
                  : () async {
                      final error = await store.markNoticesRead();
                      if (context.mounted && error != null) {
                        notice(context, error, isError: true);
                      }
                    },
              child: const Text('Mark all read'),
            ),
          for (final n in notices)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                store.readNotices.contains(n.id)
                    ? Icons.mark_email_read_outlined
                    : Icons.notifications_active_outlined,
                color: Harvest.forest,
              ),
              title: Text(n.title),
              subtitle: Text(n.message),
            ),
        ],
      ),
    );
  }
}
