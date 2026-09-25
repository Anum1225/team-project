import 'package:flutter/material.dart';

import '../data/sample_catalog.dart';
import '../state/customer_store.dart';
import '../widgets/empty_state.dart';
import '../widgets/farmer_tile.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';

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
