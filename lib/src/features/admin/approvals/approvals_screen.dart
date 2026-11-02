import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../common/data/models.dart';
import '../../common/shared/components.dart';
import '../../common/shared/theme.dart';

class AdminApprovalsScreen extends StatelessWidget {
  const AdminApprovalsScreen({super.key});

  Future<void> _decide(
    BuildContext context,
    String type,
    String id,
    String name,
    bool approve,
  ) async {
    final action = approve ? 'Approve' : 'Reject';
    final confirmed = await confirmAction(
      context,
      title: '$action $name?',
      message: approve
          ? 'This will make the $type available to the next step of the marketplace.'
          : 'This $type will be rejected. Rejected orders return reserved stock.',
      action: action,
      isDestructive: !approve,
    );
    if (!confirmed || !context.mounted) return;
    String? error;
    if (type == 'market') {
      try {
        final db = FirebaseFirestore.instance;
        final ref = db.collection('farmersMarkets').doc(id);
        final market = await ref.get();
        if (!market.exists || market.data()?['approvalStatus'] != 'pending') {
          throw StateError('Market is no longer pending.');
        }
        final batch = db.batch();
        batch.update(ref, {
          'approvalStatus': approve ? 'approved' : 'rejected',
          'active': approve,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        final owner = market.data()?['owner'];
        if (owner is String && owner.isNotEmpty) {
          batch.set(db.doc('users/$owner/notifications/approval_market_$id'), {
            'title': approve ? 'Market approved' : 'Market rejected',
            'body':
                '${market.data()?['name']} was ${approve ? 'approved' : 'rejected'} by the administrator.',
            'target': '',
            'pushDelivered': false,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      } catch (_) {
        error = 'Could not update the market approval.';
      }
    } else {
      error = await HarvestScope.of(context).decideApproval(type, id, approve);
    }
    if (context.mounted) {
      notice(
        context,
        error ?? '$name ${approve ? 'approved' : 'rejected'}.',
        isError: error != null,
      );
    }
  }

  Widget _entry(
    BuildContext context, {
    required String type,
    required String id,
    required String title,
    required String subtitle,
  }) {
    final store = HarvestScope.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            Text(
              subtitle,
              style: TextStyle(color: Harvest.colors(context).muted),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                FilledButton(
                  onPressed: store.busy
                      ? null
                      : () => _decide(context, type, id, title, true),
                  child: const Text('Approve'),
                ),
                OutlinedButton(
                  onPressed: store.busy
                      ? null
                      : () => _decide(context, type, id, title, false),
                  child: const Text('Reject'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.role != UserRole.admin || !store.authenticated) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final accounts = store.accounts
        .where((a) => a.approvalStatus == 'pending')
        .toList();
    final products = store.products
        .where((p) => p.approvalStatus == 'pending')
        .toList();
    final orders = store.orders
        .where((o) => o.approvalStatus == 'pending')
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Pending approvals')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (accounts.isEmpty && products.isEmpty && orders.isEmpty)
            const InfoNote('There are no pending approvals.'),
          if (accounts.isNotEmpty) ...[
            SectionHeader('Accounts (${accounts.length})'),
            for (final account in accounts)
              _entry(
                context,
                type: 'account',
                id: account.id,
                title: account.name,
                subtitle: '${account.role.label} · ${account.email}',
              ),
          ],
          if (products.isNotEmpty) ...[
            SectionHeader('Products (${products.length})'),
            for (final product in products)
              _entry(
                context,
                type: 'product',
                id: product.id,
                title: product.name,
                subtitle:
                    '${store.farm(product.farmId).name} · ${money(product.price)} · ${product.stock} ${product.unit}',
              ),
          ],
          if (orders.isNotEmpty) ...[
            SectionHeader('Orders (${orders.length})'),
            for (final order in orders)
              _entry(
                context,
                type: 'order',
                id: order.id,
                title: 'Order ${order.id}',
                subtitle:
                    '${order.customerName} · ${order.farmName} · ${money(order.total)}',
              ),
          ],
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('farmersMarkets')
                .where('approvalStatus', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              final markets = snapshot.data?.docs ?? [];
              if (markets.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SectionHeader('Markets (${markets.length})'),
                  for (final market in markets)
                    _entry(
                      context,
                      type: 'market',
                      id: market.id,
                      title: market.data()['name'] as String? ?? 'Market',
                      subtitle: market.data()['location'] as String? ?? '',
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
