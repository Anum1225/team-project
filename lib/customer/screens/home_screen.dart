import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import '../widgets/farm_promise.dart';
import '../widgets/farmer_tile.dart';
import '../widgets/harvest_art.dart';
import '../widgets/heading.dart';
import '../widgets/produce_illustration.dart';
import '../widgets/product_grid.dart';
import '../widgets/surface.dart';
import 'assistant_screen.dart';
import 'edit_profile_screen.dart';
import 'farmers_screen.dart';

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
          if (store.canShop)
            TextButton(
              onPressed: () =>
                  openPage(context, EditProfileScreen(store: store)),
              child: const Text('Change address'),
            ),
        ],
      ),
      Heading(
        store.isDemo
            ? 'Fresh finds, just for you.'
            : 'Fresh finds, ${store.profile.name.split(' ').first}.',
        subtitle: store.isDemo
            ? 'Demo mode · Browse and save favorites. Sign in to shop.'
            : 'Good for you. Great for your community.',
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
          FarmPromise(Icons.eco_outlined, 'Locally grown'),
          FarmPromise(Icons.handshake_outlined, 'Support small farms'),
          FarmPromise(Icons.spa_outlined, 'Seasonal & fresh'),
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
        subtitle:
            '${products.length} fresh finds from ${farmers.length} local growers.',
        trailing: TextButton(
          onPressed: () => onBrowse(),
          child: const Text('See all'),
        ),
      ),
      ProductGrid(items: products, store: store),
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
      ...farmers.map(
        (f) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FarmerTile(farmer: f, store: store),
        ),
      ),
    ],
  );
}
