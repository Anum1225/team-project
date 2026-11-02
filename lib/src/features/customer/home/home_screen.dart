part of '../customer.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.onExplore,
    required this.onAssistant,
    required this.onProfile,
  });

  final VoidCallback onExplore, onAssistant, onProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _category = 'All';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final store = HarvestScope.of(context);
    unawaited(store.assistantPreferences.load(store.account.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    final categories = ['All', ...store.categories];
    final available = store.catalogProducts(
      store.products.where(
        (product) => product.stock > 0 && store.farm(product.farmId).active,
      ),
    );
    final products =
        (_category == 'All'
              ? available
              : available
                    .where((product) => product.category == _category)
                    .toList())
          ..sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
    final upcoming = store.catalogProducts(
      store.products.where(
        (product) => product.stock == 0 && store.farm(product.farmId).active,
      ),
    )..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final address = store.account.address.trim();
    final featuredFarms = store.farms.where((f) => f.active).take(4).toList();

    return Scaffold(
      backgroundColor: palette.canvas,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: store.refresh,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(0, 4, 0, 142),
            children: [
              HarvestHubBrandHeader(
                marketName: address.isEmpty
                    ? 'Fresh from local farms'
                    : address,
                unreadNotifications: false,
                basketButton: const BasketAction(),
                notificationButton: InboxIndicator(
                  onOpen: () async {
                    await openPage(context, const NotificationsScreen());
                  },
                ),
                onLocationTap: () =>
                    openPage(context, const ProfileEditorScreen()),
                onNotificationTap: () =>
                    openPage(context, const NotificationsScreen()),
                onProfileTap: widget.onProfile,
                onThemeTap: () => ThemeReveal.toggle(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fresh finds, closer to you.',
                      style: TextStyle(
                        color: palette.ink,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Welcome, ${store.account.name.split(' ').first}. Find your next farm-fresh favourite.',
                      style: TextStyle(color: palette.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: SearchBox(
                  hint: 'Search your local market',
                  readOnly: true,
                  onTap: widget.onExplore,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 8,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => openPage(context, const WishlistScreen()),
                    icon: const Icon(Icons.favorite_border_rounded),
                    label: const Text('My Wishlist'),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: _marketplaceHero(
                  context,
                  onExplore: widget.onExplore,
                  onAssistant: widget.onAssistant,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Browse categories',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExplore,
                      child: const Text('All products'),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    return ChoiceChip(
                      label: Text(category),
                      selected: category == _category,
                      onSelected: (_) => setState(() => _category = category),
                      selectedColor: palette.green,
                      labelStyle: TextStyle(
                        color: category == _category
                            ? Colors.white
                            : palette.ink,
                        fontWeight: FontWeight.w700,
                      ),
                      side: BorderSide(
                        color: category == _category
                            ? palette.green
                            : palette.border,
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _category == 'All' ? 'Available now' : _category,
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: widget.onExplore,
                      child: const Text('See all'),
                    ),
                  ],
                ),
              ),
              if (products.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: InfoNote(
                    store.loading
                        ? 'Loading products from your market…'
                        : _category == 'All'
                        ? 'No in-stock products are listed in your market yet.'
                        : 'No in-stock products in this category yet.',
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ProductGrid(
                    products: products.take(4).toList(),
                    onOpen: (product) =>
                        openPage(context, ProductScreen(product: product)),
                  ),
                ),
              if (upcoming.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                  child: Text(
                    'Upcoming products',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: ProductGrid(
                    products: upcoming.take(4).toList(),
                    onOpen: (product) =>
                        openPage(context, ProductScreen(product: product)),
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Meet the growers',
                        style: TextStyle(
                          color: palette.ink,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          openPage(context, const AllFarmsScreen()),
                      child: const Text('Directory'),
                    ),
                  ],
                ),
              ),
              if (featuredFarms.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: InfoNote(
                    'Farmer profiles will appear here as local growers join.',
                  ),
                )
              else
                ...featuredFarms.map((farm) {
                  final stockCount = store.products
                      .where((p) => p.farmId == farm.id && p.stock > 0)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 9),
                    child: Material(
                      color: palette.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: palette.paleLeaf,
                          child: Icon(
                            Icons.agriculture_rounded,
                            color: palette.green,
                          ),
                        ),
                        title: Text(
                          farm.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          [
                            if ((farm.location.isEmpty
                                    ? farm.market
                                    : farm.location)
                                .isNotEmpty)
                              farm.location.isEmpty
                                  ? farm.market
                                  : farm.location,
                            '$stockCount products',
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Icon(
                          Icons.chevron_right_rounded,
                          color: palette.muted,
                        ),
                        onTap: () => openPage(context, FarmScreen(farm: farm)),
                      ),
                    ),
                  );
                }),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 4),
                child: _assistantInvite(
                  context,
                  palette,
                  onTap: widget.onAssistant,
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: ListenableBuilder(
        listenable: store.assistantPreferences,
        builder: (context, _) => AnimatedSwitcher(
          duration: const Duration(milliseconds: 240),
          child:
              store.assistantPreferences.enabledFor(store.account.id) == true &&
                  store.role == UserRole.customer
              ? TweenAnimationBuilder<double>(
                  key: const ValueKey('ola'),
                  tween: Tween(begin: 96, end: 0),
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (_, offset, child) => Transform.translate(
                    offset: Offset(offset + 6, 0),
                    child: child,
                  ),
                  child: AssistantRobot(
                    onTap: widget.onAssistant,
                    onDismiss: () async {
                      final saved = await store.assistantPreferences.setEnabled(
                        store.account.id,
                        false,
                      );
                      if (context.mounted && !saved) {
                        notice(
                          context,
                          'Could not save your assistant preference. Please retry.',
                          isError: true,
                        );
                      }
                    },
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }

  Widget _marketplaceHero(
    BuildContext context, {
    required VoidCallback onExplore,
    required VoidCallback onAssistant,
  }) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withValues(alpha: .12)),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF143E2B), Color(0xFF246A43), Color(0xFF37794D)],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22244531),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FROM GROWER TO TABLE',
                  style: TextStyle(
                    color: Color(0xFFCDEBCF),
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Fresh from farms\nnear your home.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 13),
                Wrap(
                  spacing: 8,
                  runSpacing: 7,
                  children: [
                    _heroAction(
                      'Shop produce',
                      Icons.arrow_forward_rounded,
                      onExplore,
                    ),
                    _heroAction(
                      'Ask the assistant',
                      Icons.auto_awesome_rounded,
                      onAssistant,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          ExcludeSemantics(
            child: Container(
              width: 52,
              height: 68,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .07),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: Colors.white.withValues(alpha: .12)),
              ),
              child: const Icon(
                Icons.eco_rounded,
                color: Color(0xFFC5E9AF),
                size: 38,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _heroAction(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: 15),
    label: Text(label),
    style: OutlinedButton.styleFrom(
      foregroundColor: label == 'Shop produce'
          ? const Color(0xFF17432D)
          : Colors.white,
      backgroundColor: label == 'Shop produce'
          ? const Color(0xFFF0F6DF)
          : Colors.white.withValues(alpha: .05),
      side: BorderSide(
        color: Colors.white.withValues(alpha: label == 'Shop produce' ? 0 : .3),
      ),
      minimumSize: const Size(0, 42),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      textStyle: const TextStyle(
        fontFamily: 'Manrope',
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
      visualDensity: VisualDensity.compact,
    ),
  );

  Widget _assistantInvite(
    BuildContext context,
    HarvestPalette palette, {
    required VoidCallback onTap,
  }) => Material(
    color: palette.surface,
    borderRadius: BorderRadius.circular(20),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: palette.paleLeaf,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.auto_awesome_rounded, color: palette.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HarvestHub assistant',
                    style: TextStyle(
                      color: palette.ink,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Ask about produce, storage, and nutrition.',
                    style: TextStyle(color: palette.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_rounded, color: palette.green, size: 18),
          ],
        ),
      ),
    ),
  );
}
