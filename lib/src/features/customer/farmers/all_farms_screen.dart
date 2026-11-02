part of '../customer.dart';

class AllFarmsScreen extends StatefulWidget {
  const AllFarmsScreen({super.key, this.followedOnly = false});
  final bool followedOnly;

  @override
  State<AllFarmsScreen> createState() => _AllFarmsScreenState();
}

class _AllFarmsScreenState extends State<AllFarmsScreen> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final query = _search.text.trim().toLowerCase();
    final farms =
        store.farms.where((farm) {
          if (!farm.active) return false;
          if (widget.followedOnly && !store.followed.contains(farm.id)) {
            return false;
          }
          if (query.isEmpty) return true;
          return '${farm.name} ${farm.location} ${farm.market} ${farm.description}'
              .toLowerCase()
              .contains(query);
        }).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );

    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(
        title: Text(
          widget.followedOnly ? 'Followed farmers' : 'Farmers & farms',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
            child: SearchBox(
              controller: _search,
              hint: 'Search farmer, farm or market…',
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: farms.isEmpty
                ? CustomerEmptyState(
                    icon: Icons.agriculture_outlined,
                    title: widget.followedOnly
                        ? 'Your growers, together.'
                        : 'Find your local growers',
                    message: query.isNotEmpty
                        ? 'No farms match that search.'
                        : widget.followedOnly
                        ? 'Follow a farm to keep its fresh harvests close.'
                        : 'Farms will appear here when growers publish their profiles.',
                    action: widget.followedOnly
                        ? OutlinedButton(
                            onPressed: () =>
                                openPage(context, const AllFarmsScreen()),
                            child: const Text('Discover farms'),
                          )
                        : null,
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 4, 18, 28),
                    itemCount: farms.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final farm = farms[i];
                      final products = store.products
                          .where((p) => p.farmId == farm.id && p.stock > 0)
                          .length;
                      final following = store.isFollowed(farm.id);
                      return Material(
                        color: palette.surface,
                        borderRadius: BorderRadius.circular(20),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: () =>
                              openPage(context, FarmScreen(farm: farm)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 54,
                                  height: 54,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(17),
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFD8F1DE),
                                        Color(0xFFB8DFC1),
                                      ],
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.agriculture_rounded,
                                    color: palette.forest,
                                    size: 27,
                                  ),
                                ),
                                const SizedBox(width: 13),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        farm.name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.ink,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 15,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        [farm.location, farm.market]
                                            .where((s) => s.trim().isNotEmpty)
                                            .join(' · ')
                                            .ifEmpty('Local farm'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: palette.muted,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 5),
                                      Text(
                                        '$products products available',
                                        style: TextStyle(
                                          color: palette.green,
                                          fontWeight: FontWeight.w700,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  tooltip: following
                                      ? 'Unfollow farmer'
                                      : 'Follow farmer',
                                  onPressed: () =>
                                      toggleFarmFollow(context, farm),
                                  icon: Icon(
                                    following
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: following
                                        ? const Color(0xFFE15D53)
                                        : palette.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
