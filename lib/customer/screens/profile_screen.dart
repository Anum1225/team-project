import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/heading.dart';
import '../widgets/price_row.dart';
import '../widgets/surface.dart';
import '../widgets/tag.dart';
import 'about_screen.dart';
import 'assistant_screen.dart';
import 'contact_screen.dart';
import 'edit_profile_screen.dart';
import 'farmers_screen.dart';
import 'notifications_screen.dart';
import 'password_screen.dart';
import 'welcome_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: store,
    child: ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Heading(
          'Your little corner',
          subtitle: 'Your details, favorite growers, and a helping hand.',
        ),
        Surface(
          child: Column(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: lime,
                child: Text(
                  store.profile.name.isEmpty
                      ? 'C'
                      : store.profile.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 30, color: green),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                store.profile.name,
                style: const TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.bold,
                  color: green,
                ),
              ),
              const SizedBox(height: 5),
              Text(store.profile.email, style: const TextStyle(color: muted)),
              const SizedBox(height: 12),
              const Tag('CUSTOMER'),
              const Divider(),
              PriceRow('Orders', '${store.orders.length}'),
              PriceRow('Saved products', '${store.wishlist.length}'),
              PriceRow('Following', '${store.followed.length}'),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Surface(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              _link(
                context,
                Icons.person_outline,
                'Edit profile',
                'Name, contact number and address',
                () => openPage(context, EditProfileScreen(store: store)),
              ),
              _link(
                context,
                Icons.lock_outline,
                'Change password',
                'Manage account security',
                () => openPage(context, PasswordScreen(store: store)),
              ),
              _link(
                context,
                Icons.agriculture_outlined,
                'Following',
                'Your favorite local growers',
                () => openPage(
                  context,
                  FarmersScreen(store: store, followedOnly: true),
                ),
              ),
              _link(
                context,
                Icons.notifications_none,
                'Notifications',
                'Orders, pickups and updates',
                () => openPage(context, NotificationsScreen(store: store)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Surface(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              _link(
                context,
                Icons.auto_awesome_outlined,
                'Farm assistant',
                'A little everyday produce wisdom',
                () => openPage(context, AssistantScreen(store: store)),
              ),
              _link(
                context,
                Icons.eco_outlined,
                'About HarvestHub',
                'Our purpose and community',
                () => openPage(context, const AboutScreen()),
              ),
              _link(
                context,
                Icons.chat_bubble_outline,
                'Contact us',
                'We would love to hear from you',
                () => openPage(context, ContactScreen(store: store)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: () async {
            final leave = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Sign out?'),
                content: const Text(
                  'Your saved profile and orders stay in your account.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stay'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Log out'),
                  ),
                ],
              ),
            );
            if (leave == true && context.mounted) {
              try {
                await store.signOut();
              } catch (e) {
                if (context.mounted) {
                  toast(context, FirebaseCustomerService.errorMessage(e));
                }
                return;
              }
              if (!context.mounted) return;
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => WelcomeScreen(store: store)),
                (_) => false,
              );
            }
          },
          icon: const Icon(Icons.logout),
          label: const Text('Log out'),
        ),
        const SizedBox(height: 24),
        const Text(
          'HarvestHub · Grown with care\nCustomer preview v1.0',
          textAlign: TextAlign.center,
          style: TextStyle(color: muted, height: 1.8, fontSize: 12),
        ),
      ],
    ),
  );
  Widget _link(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) => ListTile(
    leading: Icon(icon, color: green),
    title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
    subtitle: Text(
      subtitle,
      style: const TextStyle(fontSize: 12, color: muted),
    ),
    trailing: const Icon(Icons.chevron_right, size: 19),
    onTap: onTap,
  );
}
