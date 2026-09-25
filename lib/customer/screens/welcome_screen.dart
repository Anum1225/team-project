import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/demo_navigation.dart';
import '../utils/navigation.dart';
import '../widgets/harvest_art.dart';
import '../widgets/surface.dart';
import '../widgets/tag.dart';
import 'register_screen.dart';
import 'sign_in_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: LayoutBuilder(
              builder: (context, box) {
                final intro = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.eco, color: green, size: 32),
                        SizedBox(width: 10),
                        Text(
                          'HarvestHub',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 26,
                            color: green,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 38),
                    const Tag('GROWN LOCALLY. LOVED DAILY.'),
                    const SizedBox(height: 20),
                    Text(
                      'Good food.\nCloser to home.',
                      style: TextStyle(
                        fontSize: box.maxWidth > 700 ? 60 : 43,
                        fontWeight: FontWeight.w800,
                        height: 1.06,
                        letterSpacing: -2,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text(
                      'Meet your local growers. Fill your basket with seasonal goodness. Bring a little more fresh to your everyday.',
                      style: TextStyle(
                        fontSize: 17,
                        height: 1.65,
                        color: muted,
                      ),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () =>
                            openPage(context, RegisterScreen(store: store)),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            openPage(context, SignInScreen(store: store)),
                        child: const Text('I already have an account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => enterCustomerDemo(context, store),
                        child: const Text('Explore customer demo'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'DEMO · Browse and save favorites · Sign in to shop',
                      style: TextStyle(
                        fontSize: 11,
                        color: muted,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                );
                final photo = ClipRRect(
                  borderRadius: BorderRadius.circular(32),
                  child: Stack(
                    children: [
                      SizedBox(
                        height: box.maxWidth > 700 ? 590 : 260,
                        width: double.infinity,
                        child: const HarvestArt(),
                      ),
                      Positioned(
                        left: 22,
                        right: 22,
                        bottom: 22,
                        child: Surface(
                          child: Row(
                            children: [
                              const CircleAvatar(
                                backgroundColor: lime,
                                child: Icon(Icons.agriculture, color: green),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'From their fields\nto your family.',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return box.maxWidth > 700
                    ? Row(
                        children: [
                          Expanded(child: intro),
                          const SizedBox(width: 70),
                          Expanded(child: photo),
                        ],
                      )
                    : Column(
                        children: [photo, const SizedBox(height: 28), intro],
                      );
              },
            ),
          ),
        ),
      ),
    ),
  );
}
