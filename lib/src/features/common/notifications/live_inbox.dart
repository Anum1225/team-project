import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../shared/components.dart';
import '../data/models.dart';
import '../../customer/customer.dart' show FarmScreen, ProductScreen;
import '../orders/orders.dart';

Stream<QuerySnapshot<Map<String, dynamic>>> notificationInbox(String uid) =>
    FirebaseFirestore.instance
        .collection('users/$uid/notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

class NotificationMessage extends StatelessWidget {
  const NotificationMessage(this.message, {super.key});
  final String message;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Text(message, textAlign: TextAlign.center),
      ),
    ),
  );
}

class LiveNotificationInbox extends StatelessWidget {
  const LiveNotificationInbox({super.key});
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: notificationInbox(store.account.id),
      builder: (context, snapshot) {
        if (snapshot.hasError && store.role != UserRole.admin) {
          return const NotificationMessage(
            'Could not load notifications. Check your connection.',
          );
        }
        if (!snapshot.hasData && !snapshot.hasError) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final adminOrders = store.role == UserRole.admin
            ? (store.visibleOrders.toList()
                ..sort((a, b) => b.date.compareTo(a.date)))
            : <HarvestOrder>[];
        if (docs.isEmpty && adminOrders.isEmpty) {
          return const NotificationMessage(
            'You’re all caught up. New updates will appear here.',
          );
        }
        Future<void> read(
          List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
        ) async {
          try {
            final batch = FirebaseFirestore.instance.batch();
            for (final doc in docs.where((d) => d.data()['readAt'] == null)) {
              batch.update(doc.reference, {
                'readAt': FieldValue.serverTimestamp(),
              });
            }
            await batch.commit();
          } catch (_) {
            if (context.mounted) {
              notice(
                context,
                'Could not mark notifications as read.',
                isError: true,
              );
            }
          }
        }

        return Column(
          children: [
            if (docs.isNotEmpty)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => read(docs),
                  child: const Text('Mark all as read'),
                ),
              ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: docs.length +
                    (adminOrders.isEmpty ? 0 : adminOrders.length + 1),
                itemBuilder: (context, i) {
                  if (i >= docs.length) {
                    if (i == docs.length) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          'Platform order activity',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    final order = adminOrders[i - docs.length - 1];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text('Order ${order.id} · ${order.status.label}'),
                        subtitle: Text(
                          '${order.farmName} · ${money(order.total)}',
                        ),
                        onTap: () => openPage(
                          context,
                          OrderDetailScreen(order: order),
                        ),
                      ),
                    );
                  }
                  final doc = docs[i], data = doc.data();
                  final stamp = data['createdAt'];
                  final date = stamp is Timestamp
                      ? stamp.toDate().toLocal()
                      : null;
                  return Card(
                    child: ListTile(
                      horizontalTitleGap: store.role == UserRole.admin
                          ? 24
                          : null,
                      leading: Icon(
                        data['readAt'] == null
                            ? Icons.notifications_active
                            : Icons.notifications_none,
                      ),
                      title: Text(
                        data['title'] as String? ?? 'Market update',
                        style: TextStyle(
                          fontWeight: data['readAt'] == null
                              ? FontWeight.w700
                              : FontWeight.w400,
                        ),
                      ),
                      subtitle: Text(
                        '${data['body'] ?? ''}${date == null ? '' : '\n${date.day}/${date.month} · ${TimeOfDay.fromDateTime(date).format(context)}'}',
                      ),
                      isThreeLine: true,
                      onTap: () async {
                        await read([doc]);
                        if (!context.mounted) return;
                        final target = data['target'] as String? ?? '';
                        final id = target.split(':').skip(1).join(':');
                        if (target.startsWith('order:')) {
                          final order = store.orders
                              .where((o) => o.id == id)
                              .firstOrNull;
                          if (order != null) {
                            openPage(context, OrderDetailScreen(order: order));
                          } else {
                            notice(
                              context,
                              'This order is not in the loaded list. Refresh your orders.',
                            );
                          }
                        } else if (target.startsWith('product:')) {
                          final product = store.product(id);
                          if (product != null) {
                            openPage(context, ProductScreen(product: product));
                          } else {
                            notice(
                              context,
                              'This product is no longer available.',
                            );
                          }
                        } else if (target.startsWith('farm:')) {
                          openPage(context, FarmScreen(farmId: id));
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
