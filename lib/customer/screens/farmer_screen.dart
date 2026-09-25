import 'package:flutter/material.dart';

import '../data/pickup_slots.dart';
import '../data/sample_catalog.dart';
import '../models/farmer.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/product_grid.dart';
import '../widgets/surface.dart';

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
