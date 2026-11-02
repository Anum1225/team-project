import 'package:flutter/material.dart';

import '../components.dart';
import '../customer.dart';
import 'sign_in_required.dart';

class FollowingScreen extends StatelessWidget {
  const FollowingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.isDemo) return const SignInRequired();
    final farms = store.farms
        .where((f) => store.followed.contains(f.id))
        .toList();
    return HarvestPage(
      title: 'Following',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Your favorite growers',
            subtitle: 'Keep your local farms close.',
          ),
          if (farms.isEmpty)
            const InfoNote('Open a farm profile and follow it to see it here.'),
          for (final farm in farms)
            MenuRow(
              title: farm.name,
              subtitle: '${farm.market} · ${farm.location}',
              icon: Icons.agriculture_outlined,
              onTap: () => openPage(context, FarmScreen(farm: farm)),
            ),
        ],
      ),
    );
  }
}
