import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'About HarvestHub',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Surface(
          color: green,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.eco, color: lime, size: 54),
              SizedBox(height: 22),
              Text(
                'A stronger community.\nOne fresh basket at a time.',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              SizedBox(height: 18),
              Text(
                'We believe good food should bring people closer.',
                style: TextStyle(color: lime, fontSize: 17),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const Heading('Rooted in something good'),
        const Text(
          'HarvestHub connects customers with local growers through a simple, welcoming marketplace. Discover seasonal produce, learn about the people growing your food, and support the farms in your community.',
          style: TextStyle(color: muted, fontSize: 16, height: 1.8),
        ),
        const SizedBox(height: 24),
        ...[
          (
            Icons.spa_outlined,
            'Fresh & local',
            'Find agricultural products from nearby growers.',
          ),
          (
            Icons.handshake_outlined,
            'People first',
            'Discover farms and build a connection with your food.',
          ),
          (
            Icons.shopping_basket_outlined,
            'Simple by nature',
            'Browse, save, and plan your next basket in one place.',
          ),
        ].map(
          (v) => ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
            leading: Icon(v.$1, color: green),
            title: Text(v.$2),
            subtitle: Text(v.$3),
          ),
        ),
        const Divider(),
        const Text(
          'Customer screen preview · Version 1.0\nSample catalog, simulated orders, and session-only data.',
          style: TextStyle(color: muted, height: 1.7),
        ),
      ],
    ),
  );
}
