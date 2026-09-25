import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/empty_state.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: store.unread == 0 ? null : store.markRead,
          child: const Text('Read all'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Heading(
            'A little news from the farm',
            subtitle: 'Your order and pickup updates, all in one place.',
          ),
          const Surface(
            color: lime,
            child: Text(
              'In-app demo updates. Live restock and push notifications are not connected.',
              style: TextStyle(color: green),
            ),
          ),
          const SizedBox(height: 20),
          if (store.notices.isEmpty)
            const EmptyState(
              Icons.notifications_none,
              'All quiet for now',
              'Your next order or pickup update will appear here.',
            ),
          ...store.notices.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                color: n.read ? Colors.white : const Color(0xFFF0F4E8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      n.read
                          ? Icons.mark_email_read_outlined
                          : Icons.notifications_active_outlined,
                      color: green,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            n.message,
                            style: const TextStyle(height: 1.6, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
