import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import '../widgets/tag.dart';
import 'assistant_screen.dart';
import 'cart_screen.dart';
import 'catalog_screen.dart';
import 'home_screen.dart';
import 'notifications_screen.dart';
import 'orders_screen.dart';
import 'profile_screen.dart';
import 'wishlist_screen.dart';

class CustomerShell extends StatefulWidget {
  const CustomerShell({super.key, required this.store});
  final CustomerStore store;
  @override
  State<CustomerShell> createState() => _CustomerShellState();
}

class _CustomerShellState extends State<CustomerShell> {
  int selected = 0;
  String category = 'All';
  void browse([String value = 'All']) => setState(() {
    category = value;
    selected = 1;
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.store,
    builder: (context, _) {
      final store = widget.store;
      final wide = MediaQuery.sizeOf(context).width >= 1000;
      final pages = [
        HomeScreen(store: store, onBrowse: browse),
        CatalogScreen(
          key: ValueKey(category),
          store: store,
          initialCategory: category,
        ),
        WishlistScreen(store: store, onBrowse: browse),
        OrdersScreen(store: store, onBrowse: browse),
        ProfileScreen(store: store),
      ];
      const labels = ['Home', 'Explore', 'Wishlist', 'Orders', 'Profile'];
      const icons = [
        Icons.home_outlined,
        Icons.grid_view_outlined,
        Icons.favorite_border,
        Icons.shopping_bag_outlined,
        Icons.person_outline,
      ];
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.eco, size: 29),
              SizedBox(width: 9),
              Text(
                'HarvestHub',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.8,
                ),
              ),
            ],
          ),
          actions: [
            if (wide)
              Padding(
                padding: EdgeInsets.only(right: 18),
                child: Tag(store.isDemo ? 'DEMO · BROWSE ONLY' : 'CUSTOMER'),
              ),
            IconButton(
              tooltip: 'Notifications',
              onPressed: () =>
                  openPage(context, NotificationsScreen(store: store)),
              icon: Badge(
                isLabelVisible: store.unread > 0,
                label: Text('${store.unread}'),
                child: const Icon(Icons.notifications_none),
              ),
            ),
            IconButton(
              tooltip: 'Shopping cart',
              onPressed: () => openPage(context, CartScreen(store: store)),
              icon: Badge(
                isLabelVisible: store.cartCount > 0,
                label: Text('${store.cartCount}'),
                child: const Icon(Icons.shopping_basket_outlined),
              ),
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: SafeArea(
          child: Row(
            children: [
              if (wide)
                NavigationRail(
                  extended: true,
                  minExtendedWidth: 200,
                  backgroundColor: canvas,
                  selectedIndex: selected,
                  onDestinationSelected: (i) => setState(() => selected = i),
                  destinations: List.generate(
                    labels.length,
                    (i) => NavigationRailDestination(
                      icon: Icon(icons[i]),
                      label: Text(labels[i]),
                    ),
                  ),
                  trailing: Padding(
                    padding: const EdgeInsets.only(top: 28),
                    child: TextButton.icon(
                      onPressed: () =>
                          openPage(context, AssistantScreen(store: store)),
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Farm assistant'),
                    ),
                  ),
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1250),
                    child: Column(
                      children: [
                        if (store.syncError != null)
                          MaterialBanner(
                            content: Text(store.syncError!),
                            actions: const [SizedBox.shrink()],
                          ),
                        Expanded(child: pages[selected]),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: selected,
                onDestinationSelected: (i) => setState(() => selected = i),
                destinations: List.generate(
                  labels.length,
                  (i) => NavigationDestination(
                    icon: Icon(icons[i]),
                    label: labels[i],
                  ),
                ),
              ),
      );
    },
  );
}
