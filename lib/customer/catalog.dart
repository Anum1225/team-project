import 'package:flutter/material.dart';

import 'store.dart';
import 'ui.dart';
import 'shopping.dart';
import 'account.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.store, required this.onBrowse});
  final CustomerStore store;
  final void Function([String category]) onBrowse;
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(22, 8, 22, 28),
    children: [
      Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 17, color: green),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              'Discover local goodness · Karachi',
              style: TextStyle(color: muted, fontSize: 12),
            ),
          ),
          TextButton(
            onPressed: () => openPage(context, EditProfileScreen(store: store)),
            child: const Text('Change address'),
          ),
        ],
      ),
      Heading(
        'Fresh finds, ${store.profile.name.split(' ').first}.',
        subtitle: 'Good for you. Great for your community.',
      ),
      TextField(
        readOnly: true,
        onTap: () => onBrowse(),
        decoration: const InputDecoration(
          hintText: 'Search fresh produce, farms & markets',
          prefixIcon: Icon(Icons.search),
          suffixIcon: Icon(Icons.tune),
        ),
      ),
      const SizedBox(height: 24),
      ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: LayoutBuilder(
          builder: (context, box) => Container(
            constraints: const BoxConstraints(minHeight: 260),
            color: green,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Padding(
                    padding: EdgeInsets.all(box.maxWidth < 500 ? 23 : 34),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'THE SEASON’S BEST',
                          style: TextStyle(
                            color: lime,
                            letterSpacing: 2.3,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Fresh from the farm.\nFull of goodness.',
                          style: TextStyle(
                            fontSize: box.maxWidth < 500 ? 29 : 39,
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            height: 1.12,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Small farms. Big flavor. Picked just for you.',
                          style: TextStyle(
                            color: Color(0xFFCCD9C8),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 22),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: lime,
                            foregroundColor: green,
                          ),
                          onPressed: () => onBrowse(),
                          label: const Text('Shop the harvest'),
                          icon: const Icon(Icons.arrow_forward, size: 18),
                        ),
                      ],
                    ),
                  ),
                ),
                if (box.maxWidth >= 580)
                  Expanded(
                    flex: 4,
                    child: const SizedBox(height: 305, child: HarvestArt()),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 22),
      const Wrap(
        spacing: 24,
        runSpacing: 12,
        children: [
          _Promise(Icons.eco_outlined, 'Locally grown'),
          _Promise(Icons.handshake_outlined, 'Support small farms'),
          _Promise(Icons.spa_outlined, 'Seasonal & fresh'),
        ],
      ),
      const SizedBox(height: 25),
      Heading(
        'Shop by category',
        trailing: TextButton(
          onPressed: () => onBrowse(),
          child: const Text('View all'),
        ),
      ),
      SizedBox(
        height: 92,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length - 1,
          separatorBuilder: (_, _) => const SizedBox(width: 12),
          itemBuilder: (context, i) {
            const illustrations = [
              'carrot',
              'strawberry',
              'wheat',
              'milk',
              'lentil',
              'basil',
              'avocado',
            ];
            return InkWell(
              borderRadius: BorderRadius.circular(15),
              onTap: () => onBrowse(categories[i + 1]),
              child: Container(
                width: 104,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFFE3E7DD)),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ProduceIllustration(id: illustrations[i], size: 32),
                    const SizedBox(height: 7),
                    Text(
                      categories[i + 1],
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      const SizedBox(height: 28),
      Heading(
        'Fresh picks for your basket',
        subtitle: 'A taste of what our local growers have to offer.',
        trailing: TextButton(
          onPressed: () => onBrowse(),
          child: const Text('See all'),
        ),
      ),
      ProductGrid(items: products.take(4).toList(), store: store),
      const SizedBox(height: 28),
      Surface(
        color: const Color(0xFFEAF0DE),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 27,
              backgroundColor: Colors.white,
              child: Icon(Icons.auto_awesome, color: green),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'A little help from the farm\nAsk about produce, storage & seasonal picks.',
                style: TextStyle(color: green, height: 1.6),
              ),
            ),
            IconButton(
              tooltip: 'Open farm assistant',
              onPressed: () => openPage(context, AssistantScreen(store: store)),
              icon: const Icon(Icons.arrow_forward),
            ),
          ],
        ),
      ),
      const SizedBox(height: 28),
      Heading(
        'Meet the hands behind the harvest',
        trailing: TextButton(
          onPressed: () => openPage(context, FarmersScreen(store: store)),
          child: const Text('All farms'),
        ),
      ),
      ...farmers
          .take(2)
          .map(
            (f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FarmerTile(farmer: f, store: store),
            ),
          ),
    ],
  );
}

class _Promise extends StatelessWidget {
  const _Promise(this.icon, this.label);
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 17, color: green),
      const SizedBox(width: 7),
      Text(label, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );
}

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    super.key,
    required this.store,
    this.initialCategory = 'All',
  });
  final CustomerStore store;
  final String initialCategory;
  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late String category = widget.initialCategory;
  final search = TextEditingController();
  String farmer = 'All', market = 'All', location = 'All', sort = 'Featured';
  double distance = 20;
  bool inStock = false;
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<Product> get filtered {
    final query = search.text.trim().toLowerCase();
    final list = products
        .where(
          (p) =>
              (category == 'All' ||
                  p.category == category ||
                  category == 'Organic' && p.organic) &&
              '${p.name} ${p.category} ${p.farmer.name} ${p.farmer.market} ${p.farmer.location}'
                  .toLowerCase()
                  .contains(query) &&
              (farmer == 'All' || p.farmerId == farmer) &&
              (market == 'All' || p.farmer.market == market) &&
              (location == 'All' || p.farmer.location == location) &&
              p.farmer.distance <= distance &&
              (!inStock || widget.store.stock(p) > 0),
        )
        .toList();
    if (sort == 'Price: low to high') {
      list.sort((a, b) => a.price.compareTo(b.price));
    }
    if (sort == 'Price: high to low') {
      list.sort((a, b) => b.price.compareTo(a.price));
    }
    if (sort == 'Nearest farm') {
      list.sort((a, b) => a.farmer.distance.compareTo(b.farmer.distance));
    }
    return list;
  }

  Future<void> filters() async {
    var nextFarmer = farmer, nextMarket = market, nextLocation = location;
    var nextDistance = distance;
    var nextStock = inStock;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => StatefulBuilder(
        builder: (context, update) => SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Heading(
                  'Find your kind of fresh',
                  subtitle: 'Filter by the farms and markets near you.',
                ),
                DropdownButtonFormField<String>(
                  initialValue: nextFarmer,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Farmer'),
                  items: [
                    const DropdownMenuItem(
                      value: 'All',
                      child: Text('All farmers'),
                    ),
                    ...farmers.map(
                      (f) => DropdownMenuItem(value: f.id, child: Text(f.name)),
                    ),
                  ],
                  onChanged: (v) => update(() => nextFarmer = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextMarket,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Market'),
                  items: ['All', ...farmers.map((f) => f.market).toSet()]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'All' ? 'All markets' : v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => nextMarket = v!),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: nextLocation,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Location'),
                  items: ['All', 'Clifton', 'Gulshan']
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'All' ? 'All locations' : v),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => update(() => nextLocation = v!),
                ),
                const SizedBox(height: 20),
                Text('Within ${nextDistance.round()} km'),
                Slider(
                  value: nextDistance,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${nextDistance.round()} km',
                  onChanged: (v) => update(() => nextDistance = v),
                ),
                const Text(
                  'Distances are sample values from central Karachi.',
                  style: TextStyle(color: muted, fontSize: 12),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Only show available products'),
                  value: nextStock,
                  onChanged: (v) => update(() => nextStock = v),
                ),
                FilledButton(
                  onPressed: () {
                    setState(() {
                      farmer = nextFarmer;
                      market = nextMarket;
                      location = nextLocation;
                      distance = nextDistance;
                      inStock = nextStock;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Apply filters'),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      farmer = market = location = 'All';
                      distance = 20;
                      inStock = false;
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Reset filters'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filtered;
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Heading(
          'Explore the harvest',
          subtitle: 'Fresh food. Real growers. A better everyday basket.',
        ),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Products, farmers or markets',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: search.text.isEmpty
                      ? null
                      : IconButton(
                          tooltip: 'Clear search',
                          onPressed: () => setState(search.clear),
                          icon: const Icon(Icons.close),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              onPressed: filters,
              tooltip: 'Search filters',
              icon: const Icon(Icons.tune),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: categories
              .map(
                (c) => ChoiceChip(
                  label: Text(c),
                  selected: category == c,
                  onSelected: (_) => setState(() => category = c),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 20,
          children: [
            Text(
              '${items.length} fresh finds',
              style: const TextStyle(color: muted),
            ),
            DropdownButton<String>(
              value: sort,
              underline: const SizedBox.shrink(),
              items:
                  [
                        'Featured',
                        'Price: low to high',
                        'Price: high to low',
                        'Nearest farm',
                      ]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v, style: const TextStyle(fontSize: 13)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => sort = v!),
            ),
          ],
        ),
        if (items.isEmpty)
          EmptyState(
            Icons.search_off,
            'No fresh finds yet',
            'Try another keyword or broaden your filters.',
            action: TextButton(
              onPressed: () => setState(() {
                search.clear();
                category = farmer = market = location = 'All';
                distance = 20;
                inStock = false;
              }),
              child: const Text('Clear all filters'),
            ),
          )
        else
          ProductGrid(items: items, store: widget.store),
      ],
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.items, required this.store});
  final List<Product> items;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final columns = box.maxWidth > 850
          ? 4
          : box.maxWidth > 570
          ? 3
          : box.maxWidth < 300
          ? 1
          : 2;
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 16,
          crossAxisSpacing: 14,
          mainAxisExtent: 294,
        ),
        itemBuilder: (context, i) =>
            ProductCard(product: items[i], store: store),
      );
    },
  );
}

class ProductCard extends StatelessWidget {
  const ProductCard({super.key, required this.product, required this.store});
  final Product product;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    borderRadius: BorderRadius.circular(19),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: () =>
          openPage(context, ProductScreen(product: product, store: store)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 135,
              child: Stack(
                children: [
                  Positioned.fill(child: ProductArt(product)),
                  if (product.organic)
                    const Positioned(
                      top: 9,
                      left: 8,
                      child: Tag('ORGANIC', color: Colors.white),
                    ),
                  Positioned(
                    top: 2,
                    right: 0,
                    child: IconButton(
                      tooltip: store.wishlist.contains(product.id)
                          ? 'Remove ${product.name} from wishlist'
                          : 'Save ${product.name}',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: .85),
                      ),
                      onPressed: () => store.toggleWish(product.id),
                      icon: Icon(
                        store.wishlist.contains(product.id)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: green,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 11),
            Text(
              product.farmer.name.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 9,
                letterSpacing: 1,
                color: muted,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: green,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${product.category} · ${store.stock(product)} available',
              maxLines: 1,
              style: const TextStyle(fontSize: 10, color: muted),
            ),
            const Spacer(),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: money(product.price),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: green,
                            fontSize: 15,
                          ),
                        ),
                        TextSpan(
                          text: ' / ${product.unit}',
                          style: const TextStyle(color: muted, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ),
                IconButton.filled(
                  tooltip: 'Add ${product.name} to cart',
                  onPressed:
                      store.stock(product) <= (store.cart[product.id] ?? 0)
                      ? null
                      : () {
                          store.add(product);
                          toast(
                            context,
                            '${product.name} added to your basket',
                          );
                        },
                  icon: const Icon(Icons.add, size: 19),
                  style: IconButton.styleFrom(
                    minimumSize: const Size(36, 36),
                    padding: const EdgeInsets.all(7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key, required this.product, required this.store});
  final Product product;
  final CustomerStore store;
  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  int quantity = 1;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final p = widget.product, store = widget.store;
      final available = store.stock(p) - (store.cart[p.id] ?? 0);
      return PageFrame(
        title: 'Fresh from the farm',
        actions: [
          IconButton(
            tooltip: 'Shopping cart',
            onPressed: () => openPage(context, CartScreen(store: store)),
            icon: Badge(
              label: Text('${store.cartCount}'),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
          ),
        ],
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(height: 280, child: ProductArt(p, size: 145)),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              children: [
                Tag(p.category),
                if (p.organic) const Tag('Organically grown'),
                Tag(
                  store.stock(p) > 0
                      ? '${store.stock(p)} in stock'
                      : 'Out of stock',
                ),
              ],
            ),
            Heading(
              p.name,
              subtitle: p.farmer.name,
              trailing: IconButton(
                tooltip: 'Toggle wishlist',
                onPressed: () => store.toggleWish(p.id),
                icon: Icon(
                  store.wishlist.contains(p.id)
                      ? Icons.favorite
                      : Icons.favorite_border,
                ),
              ),
            ),
            Text(
              '${money(p.price)} / ${p.unit}',
              style: const TextStyle(
                fontSize: 26,
                color: green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              p.description,
              style: const TextStyle(color: muted, height: 1.8, fontSize: 16),
            ),
            const Divider(),
            FarmerTile(farmer: p.farmer, store: store),
            const SizedBox(height: 24),
            const Surface(
              color: lime,
              child: Text(
                'A fresher way to shop\nChoose a pickup time at checkout. Orders in this preview are simulated.',
                style: TextStyle(color: green, height: 1.7),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 20,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                QuantityPicker(
                  value: quantity,
                  min: 1,
                  max: available,
                  onChanged: (v) => setState(() => quantity = v),
                ),
                FilledButton.icon(
                  onPressed: available < quantity
                      ? null
                      : () {
                          if (store.add(p, quantity)) {
                            toast(context, 'Added to your basket');
                            setState(() => quantity = 1);
                          }
                        },
                  icon: const Icon(Icons.shopping_basket_outlined),
                  label: Text(
                    available <= 0
                        ? 'Unavailable'
                        : 'Add to basket · ${money(p.price * quantity)}',
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({
    super.key,
    required this.store,
    required this.onBrowse,
  });
  final CustomerStore store;
  final VoidCallback onBrowse;
  @override
  Widget build(BuildContext context) => store.wishlist.isEmpty
      ? EmptyState(
          Icons.favorite_border,
          'Keep the good stuff close',
          'Save your favorite produce and come back when your basket needs a little fresh.',
          action: FilledButton(
            onPressed: onBrowse,
            child: const Text('Explore the harvest'),
          ),
        )
      : ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Heading(
              'Your wishlist',
              subtitle:
                  '${store.wishlist.length} favorites, saved for another day.',
            ),
            const Text(
              'Restock push alerts will be available when live services are connected.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            ProductGrid(
              items: products
                  .where((p) => store.wishlist.contains(p.id))
                  .toList(),
              store: store,
            ),
          ],
        );
}

class FarmerTile extends StatelessWidget {
  const FarmerTile({super.key, required this.farmer, required this.store});
  final Farmer farmer;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Surface(
    padding: const EdgeInsets.all(6),
    child: ListTile(
      onTap: () =>
          openPage(context, FarmerScreen(farmer: farmer, store: store)),
      leading: CircleAvatar(
        backgroundColor: lime,
        child: Text(
          farmer.initials,
          style: const TextStyle(color: green, fontWeight: FontWeight.bold),
        ),
      ),
      title: Text(
        farmer.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text('${farmer.location} · ${farmer.distance} km away'),
      trailing: const Icon(Icons.chevron_right),
    ),
  );
}

class FarmersScreen extends StatelessWidget {
  const FarmersScreen({
    super.key,
    required this.store,
    this.followedOnly = false,
  });
  final CustomerStore store;
  final bool followedOnly;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final list = farmers
          .where((f) => !followedOnly || store.followed.contains(f.id))
          .toList();
      return PageFrame(
        title: followedOnly ? 'Following' : 'Our local growers',
        child: list.isEmpty
            ? const EmptyState(
                Icons.agriculture_outlined,
                'Meet your favorite grower',
                'Follow farms from Explore or a product detail page to find them here.',
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Heading(
                    'Good food starts with good people',
                    subtitle: 'Discover the stories behind your basket.',
                  ),
                  ...list.map(
                    (f) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: FarmerTile(farmer: f, store: store),
                    ),
                  ),
                ],
              ),
      );
    },
  );
}

class FarmerScreen extends StatelessWidget {
  const FarmerScreen({super.key, required this.farmer, required this.store});
  final Farmer farmer;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      title: 'Meet your grower',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Surface(
            color: lime,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.agriculture, size: 54, color: green),
                Heading(
                  farmer.name,
                  subtitle:
                      '${farmer.market}\n${farmer.location} · ${farmer.distance} km away',
                ),
                Text(
                  farmer.story,
                  style: const TextStyle(height: 1.7, color: green),
                ),
                const SizedBox(height: 22),
                FilledButton.icon(
                  onPressed: () => store.toggleFollow(farmer.id),
                  icon: Icon(
                    store.followed.contains(farmer.id)
                        ? Icons.check
                        : Icons.add,
                  ),
                  label: Text(
                    store.followed.contains(farmer.id)
                        ? 'Following farm'
                        : 'Follow farm',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Heading(
            'Available pickup times',
            subtitle: 'Sample availability · Choose a slot during checkout.',
          ),
          ...pickupSlots().map(
            (s) => ListTile(
              leading: const Icon(Icons.schedule, color: green),
              title: Text(s),
            ),
          ),
          const SizedBox(height: 20),
          const Heading('From this farm'),
          ProductGrid(
            items: products.where((p) => p.farmerId == farmer.id).toList(),
            store: store,
          ),
        ],
      ),
    ),
  );
}
