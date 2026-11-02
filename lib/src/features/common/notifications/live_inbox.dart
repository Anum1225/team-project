import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../shared/components.dart';
import '../data/models.dart';
import '../data/store.dart';
import '../../customer/customer.dart' show FarmScreen, ProductScreen;
import '../orders/orders.dart';
import '../../admin/approvals/approvals_screen.dart';

Stream<QuerySnapshot<Map<String, dynamic>>> notificationInbox(String uid) =>
    FirebaseFirestore.instance
        .collection('users/$uid/notifications')
        .orderBy('createdAt', descending: true)
        .limit(100)
        .snapshots();

Stream<QuerySnapshot<Map<String, dynamic>>> pendingAccountUpdates() =>
    FirebaseFirestore.instance
        .collection('users')
        .where('approvalStatus', isEqualTo: 'pending')
        .snapshots();

Stream<QuerySnapshot<Map<String, dynamic>>> pendingMarketUpdates() =>
    FirebaseFirestore.instance
        .collection('farmersMarkets')
        .where('approvalStatus', isEqualTo: 'pending')
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
    if (store.role == UserRole.admin) {
      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: pendingAccountUpdates(),
        builder: (context, snapshot) => StreamBuilder(
          stream: pendingMarketUpdates(),
          builder: (context, markets) => _inbox(
            context,
            store,
            snapshot.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
            markets.data?.docs ??
                <QueryDocumentSnapshot<Map<String, dynamic>>>[],
          ),
        ),
      );
    }
    return _inbox(
      context,
      store,
      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
      <QueryDocumentSnapshot<Map<String, dynamic>>>[],
    );
  }

  Widget _inbox(
    BuildContext context,
    HarvestStore store,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingAccounts,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> pendingMarkets,
  ) {
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
        final docs =
            snapshot.data?.docs ??
            <QueryDocumentSnapshot<Map<String, dynamic>>>[];
        final adminOrders = store.role == UserRole.admin
            ? (store.visibleOrders.toList()
                ..sort((a, b) => b.date.compareTo(a.date)))
            : <HarvestOrder>[];
        if (docs.isEmpty &&
            adminOrders.isEmpty &&
            pendingAccounts.isEmpty &&
            pendingMarkets.isEmpty) {
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
                itemCount:
                    docs.length +
                    (pendingAccounts.isEmpty ? 0 : pendingAccounts.length + 1) +
                    (pendingMarkets.isEmpty ? 0 : pendingMarkets.length + 1) +
                    (adminOrders.isEmpty ? 0 : adminOrders.length + 1),
                itemBuilder: (context, i) {
                  final accountStart = docs.length;
                  final orderStart =
                      accountStart +
                      (pendingAccounts.isEmpty
                          ? 0
                          : pendingAccounts.length + 1) +
                      (pendingMarkets.isEmpty ? 0 : pendingMarkets.length + 1);
                  final marketStart =
                      accountStart +
                      (pendingAccounts.isEmpty
                          ? 0
                          : pendingAccounts.length + 1);
                  if (i >= accountStart && i < marketStart) {
                    if (i == accountStart) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          'Account approval requests',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    final account = pendingAccounts[i - accountStart - 1];
                    final data = account.data();
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.person_add_alt_1_outlined),
                        title: Text(
                          '${data['name'] ?? 'New account'} · ${data['role'] ?? 'user'}',
                        ),
                        subtitle: Text(
                          '${data['email'] ?? ''}\nAwaiting admin approval',
                        ),
                        isThreeLine: true,
                        onTap: () =>
                            openPage(context, const AdminApprovalsScreen()),
                      ),
                    );
                  }
                  if (i >= marketStart && i < orderStart) {
                    if (i == marketStart) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          'Market approval requests',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    final market = pendingMarkets[i - marketStart - 1].data();
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.storefront_outlined),
                        title: Text(market['name'] as String? ?? 'Market'),
                        subtitle: const Text('Awaiting administrator approval'),
                        onTap: () =>
                            openPage(context, const AdminApprovalsScreen()),
                      ),
                    );
                  }
                  if (i >= orderStart) {
                    if (i == orderStart) {
                      return const Padding(
                        padding: EdgeInsets.fromLTRB(8, 16, 8, 8),
                        child: Text(
                          'Platform order activity',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      );
                    }
                    final order = adminOrders[i - orderStart - 1];
                    return Card(
                      child: ListTile(
                        leading: const Icon(Icons.receipt_long_outlined),
                        title: Text(
                          'Order ${order.id} · ${order.status.label}',
                        ),
                        subtitle: Text(
                          '${order.farmName} · ${money(order.total)}',
                        ),
                        onTap: () =>
                            openPage(context, OrderDetailScreen(order: order)),
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
