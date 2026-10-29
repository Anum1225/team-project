part of '../../common/management/operations.dart';

class UserDetailScreen extends StatelessWidget {
  const UserDetailScreen({super.key, required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.live && (!store.authenticated || store.role != UserRole.admin)) {
      return const Scaffold(
        body: Center(child: Text('Administrator access required.')),
      );
    }
    final account =
        store.accounts.where((a) => a.id == this.account.id).firstOrNull ??
        this.account;
    final farms = store.farms.where((f) => f.owner == account.id).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      appBar: AppBar(
        title: Text(
          account.role.label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: CircleAvatar(
              radius: 38,
              backgroundColor: Harvest.colors(context).paleLeaf,
              child: Text(
                account.name[0],
                style: Harvest.editorial(32, color: Harvest.forest),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            account.name,
            textAlign: TextAlign.center,
            style: Harvest.editorial(26),
          ),
          Text(
            account.email,
            textAlign: TextAlign.center,
            style: TextStyle(color: Harvest.colors(context).muted),
          ),
          const SizedBox(height: 16),
          Center(
            child: StatusBadge(
              account.active ? 'Account Active' : 'Account Suspended',
              success: account.active,
              warning: !account.active,
            ),
          ),
          const SizedBox(height: 24),
          Text('ID: ${account.id}'),
          if (account.createdAt != null)
            Text('Joined: ${dateLabel(account.createdAt!)}'),
          HarvestButton(
            label: 'Edit contact details',
            onPressed: () =>
                openPage(context, ProfileEditorScreen(account: account)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Contact Information',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          const SizedBox(height: 8),
          Text(
            'Phone: ${account.phone.isEmpty ? "Not provided" : account.phone}',
          ),
          const SizedBox(height: 4),
          Text(
            'Address: ${account.address.isEmpty ? "Not provided" : account.address}',
          ),
          if (farms.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Farm Information',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 8),
            for (final f in farms) ...[
              FarmerTile(farm: f),
              HarvestButton(
                label: 'Edit farm information',
                onPressed: () => openPage(context, FarmEditorScreen(farm: f)),
              ),
              const SectionHeader('Products'),
              for (final p in store.products.where((p) => p.farmId == f.id))
                InventoryRow(product: p),
            ],
          ],
          const SectionHeader('Orders in loaded pages'),
          for (final o in store.orders.where(
            (o) => account.role == UserRole.customer
                ? o.customerId == account.id
                : farms.any((f) => f.id == o.farmId),
          ))
            OrderCard(order: o),
          if (store.hasMore)
            TextButton(
              onPressed: store.loadMore,
              child: const Text('Load more records'),
            ),
          const SizedBox(height: 28),
          HarvestButton(
            label: account.active ? 'Suspend Account' : 'Reactivate Account',
            outlined: true,
            color: account.active ? Harvest.danger : Harvest.forest,
            onPressed: () async {
              final action = account.active ? 'Suspend' : 'Reactivate';
              if (await confirmAction(
                context,
                title: '$action ${account.name}?',
                message: 'Suspended accounts cannot use the platform or receive new orders. Historical records are retained.',
                action: action,
                isDestructive: account.active,
              )) {
                final result = await store.toggleAccount(account);
                if (context.mounted) {
                  notice(
                    context,
                    result ?? "Account status updated",
                    isError: result != null,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
