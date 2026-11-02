part of '../customer.dart';

class FarmerTile extends StatelessWidget {
  const FarmerTile({super.key, required this.farm});
  final Farm farm;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: Harvest.colors(context).surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: Harvest.colors(context).border),
    ),
    child: Material(
      color: Colors.transparent,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Photo(farm.image, width: 44, height: 44, radius: 12),
        title: Text(
          farm.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: Text(
          '${farm.location} · ${farm.market}',
          style: TextStyle(fontSize: 12, color: Harvest.colors(context).muted),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 13,
          color: Harvest.colors(context).muted,
        ),
        onTap: () => openPage(context, FarmScreen(farm: farm)),
      ),
    ),
  );
}

class FarmScreen extends StatelessWidget {
  const FarmScreen({super.key, this.farm, this.farmId});
  final Farm? farm;
  final String? farmId;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final id = farmId ?? farm?.id;
    final f = id == null
        ? null
        : store.farms.where((f) => f.id == id).firstOrNull ?? farm;
    if (f == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Farm Profile')),
        body: const Center(child: Text('Farm not found')),
      );
    }
    final products = store.products.where((p) => p.farmId == f.id).toList();

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            actions: [
              IconButton(
                icon: Icon(
                  store.isFollowed(f.id)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: store.isFollowed(f.id)
                      ? const Color(0xFFEF4444)
                      : Colors.white,
                ),
                tooltip: store.isFollowed(f.id)
                    ? 'Unfollow Farm'
                    : 'Follow Farm & Get Restock Alerts',
                onPressed: () => toggleFarmFollow(context, f),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Photo(f.image, radius: 0, width: double.infinity),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Eyebrow(f.market)),
                      TextButton.icon(
                        onPressed: () => toggleFarmFollow(context, f),
                        style: TextButton.styleFrom(
                          backgroundColor: store.isFollowed(f.id)
                              ? const Color(0xFF16A34A).withValues(alpha: 0.12)
                              : Harvest.colors(context).surface,
                          foregroundColor: store.isFollowed(f.id)
                              ? const Color(0xFF16A34A)
                              : Harvest.colors(context).ink,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(
                              color: store.isFollowed(f.id)
                                  ? const Color(0xFF16A34A)
                                  : Harvest.colors(context).border,
                            ),
                          ),
                        ),
                        icon: Icon(
                          store.isFollowed(f.id)
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          size: 16,
                          color: store.isFollowed(f.id)
                              ? const Color(0xFFEF4444)
                              : Harvest.colors(context).muted,
                        ),
                        label: Text(
                          store.isFollowed(f.id) ? 'Following' : 'Follow Farm',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(f.name, style: Harvest.editorial(32)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: Harvest.colors(context).muted,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          f.location,
                          style: TextStyle(
                            color: Harvest.colors(context).muted,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (store.isFollowed(f.id)) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFF16A34A)
                              .withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.notifications_active_outlined,
                            size: 16,
                            color: Color(0xFF16A34A),
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'This farm is saved in your following list.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF16A34A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    f.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: Harvest.colors(context).ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (store.role == UserRole.customer)
                    OutlinedButton.icon(
                      onPressed: () => openPage(
                        context,
                        FarmerFeedbackScreen(farmId: f.id, farmName: f.name),
                      ),
                      icon: const Icon(Icons.rate_review_outlined),
                      label: const Text('Send farmer feedback'),
                    ),
                  const SizedBox(height: 24),
                  SectionHeader('Harvests Available (${products.length})'),
                  ProductGrid(
                    products: products,
                    onOpen: (p) => openPage(context, ProductScreen(product: p)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
