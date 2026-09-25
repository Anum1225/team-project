import 'package:flutter/material.dart';

import '../models/farmer.dart';
import '../screens/farmer_screen.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import 'surface.dart';

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
