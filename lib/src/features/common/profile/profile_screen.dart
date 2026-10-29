part of 'profile.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onExit});
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final account = store.account;
    final admin = store.role == UserRole.admin;
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final wishlistedCount = store.saved.length;
    final orderCount = store.role == UserRole.customer
        ? store.orders.where((o) => o.customerId == account.id).length
        : store.visibleOrders.length;
    final followedCount = store.followed.length;
    final orderPage = const HarvestPage(title: 'Orders', child: OrdersScreen());
    final statItems = switch (store.role) {
      UserRole.customer => [
        (
          Icons.favorite_rounded,
          const Color(0xFFEF4444),
          '$wishlistedCount',
          'Saved',
          () => openPage(context, const WishlistScreen()),
        ),
        (
          Icons.shopping_bag_outlined,
          const Color(0xFFD97706),
          '$orderCount',
          'Orders',
          () => openPage(context, orderPage),
        ),
        (
          Icons.spa_outlined,
          const Color(0xFF10B981),
          '$followedCount',
          'Following',
          () => openPage(context, const AllFarmsScreen(followedOnly: true)),
        ),
      ],
      UserRole.farmer => [
        (
          Icons.inventory_2_outlined,
          const Color(0xFF10B981),
          '${store.visibleProducts.length}',
          'Products',
          () => openPage(context, const InventoryScreen()),
        ),
        (
          Icons.receipt_long_outlined,
          const Color(0xFFD97706),
          '$orderCount',
          'Orders',
          () => openPage(context, orderPage),
        ),
        (
          Icons.eco_outlined,
          const Color(0xFF528C60),
          '${store.visibleProducts.fold<int>(0, (sum, p) => sum + p.stock)}',
          'Units in stock',
          () => openPage(context, const InventoryScreen()),
        ),
      ],
      UserRole.admin => [
        (
          Icons.people_outline_rounded,
          const Color(0xFF10B981),
          store.report?['users']?.toString() ?? '${store.accounts.length}',
          'Accounts',
          () => openPage(context, const UsersScreen()),
        ),
        (
          Icons.agriculture_outlined,
          const Color(0xFF528C60),
          store.report?['farmerCount']?.toString() ?? '${store.farms.length}',
          'Farmers',
          () => openPage(context, const UsersScreen()),
        ),
        (
          Icons.receipt_long_outlined,
          const Color(0xFFD97706),
          store.report?['totalOrders']?.toString() ?? '${store.orders.length}',
          'Orders',
          () => openPage(context, orderPage),
        ),
      ],
    };

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            // Top App Bar / Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  admin ? 'Admin Profile' : 'My Profile',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 22,
                    color: palette.ink,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => openPage(
                    context,
                    admin
                        ? AdminSettingsScreen(
                            onUsers: () =>
                                openPage(context, const UsersScreen()),
                            onCategories: () =>
                                openPage(context, const CategoriesScreen()),
                          )
                        : const PreferencesScreen(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Profile Card with Avatar & Edit Badge
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: palette.border, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.20 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.paleLeaf,
                          border: Border.all(
                            color: palette.green.withValues(alpha: 0.3),
                            width: 2.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: AvatarPortrait(
                          value: account.avatar.isEmpty
                              ? 'preset:${account.id.runes.fold<int>(0, (sum, rune) => sum + rune) % 12}'
                              : account.avatar,
                          size: 74,
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => openPage(
                            context,
                            ProfileAvatarPicker(account: account),
                          ),
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                              color: Color(0xFF10B981),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    account.name,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: palette.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    account.email,
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 12,
                      color: palette.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (account.phone.isNotEmpty)
                    Text(
                      account.phone,
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        color: palette.muted,
                      ),
                    ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => openPage(
                      context,
                      ProfileAvatarPicker(account: account),
                    ),
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 14,
                      color: Colors.white,
                    ),
                    label: const Text(
                      'Change portrait',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: palette.green,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      minimumSize: Size.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3 Stat Counters in a Card (matching Image 3 Screen 7)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
              decoration: BoxDecoration(
                color: palette.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: palette.border, width: 1.2),
              ),
              child: Row(
                children: [
                  for (var i = 0; i < statItems.length; i++) ...[
                    if (i > 0)
                      Container(width: 1, height: 40, color: palette.border),
                    Expanded(
                      child: _statPill(
                        statItems[i].$1,
                        statItems[i].$2,
                        statItems[i].$3,
                        statItems[i].$4,
                        statItems[i].$5,
                        palette,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Customer / Farmer / Admin Menu Items
            if (admin) ...[
              const SectionHeader('Admin Operations'),
              MenuRow(
                title: 'Analytics & Sales',
                subtitle: 'Revenue charts and performance metrics',
                icon: Icons.analytics_outlined,
                onTap: () => openPage(context, const AdminAnalyticsScreen()),
              ),
              MenuRow(
                title: 'Categories Catalog',
                subtitle: 'Manage categories and organize produce',
                icon: Icons.category_outlined,
                onTap: () => openPage(context, const CategoriesScreen()),
              ),
              MenuRow(
                title: 'Customer Feedback',
                subtitle: 'Read messages submitted by customers',
                icon: Icons.star_outline_rounded,
                onTap: () => openPage(context, const ReviewsScreen()),
              ),
              MenuRow(
                title: 'Platform Reports',
                subtitle: 'Live order, value and farmer summaries',
                icon: Icons.assessment_outlined,
                onTap: () => openPage(context, const AdminReportsScreen()),
              ),
              MenuRow(
                title: 'Accounts & Access',
                subtitle: 'Manage live customer and farmer accounts',
                icon: Icons.people_outline_rounded,
                onTap: () => openPage(context, const UsersScreen()),
              ),
              MenuRow(
                title: 'App & System Settings',
                subtitle: 'Appearance and platform tools',
                icon: Icons.settings_suggest_outlined,
                onTap: () => openPage(
                  context,
                  AdminSettingsScreen(
                    onUsers: () => openPage(context, const UsersScreen()),
                    onCategories: () =>
                        openPage(context, const CategoriesScreen()),
                  ),
                ),
              ),
            ] else ...[
              const SectionHeader('Account & Preferences'),
              MenuRow(
                title: 'App settings',
                subtitle: 'Assistant and appearance preferences',
                icon: Icons.tune_rounded,
                onTap: () => openPage(context, const PreferencesScreen()),
              ),
              MenuRow(
                title: 'My Addresses',
                subtitle: 'Manage your saved address and map location',
                icon: Icons.location_on_outlined,
                onTap: () => openPage(
                  context,
                  store.isDemo
                      ? const GuestAccountPrompt(title: 'Your saved addresses')
                      : const ProfileEditorScreen(),
                ),
              ),
              MenuRow(
                title: 'My Favorite Farmers',
                subtitle: 'Growers you follow',
                icon: Icons.spa_outlined,
                onTap: () =>
                    openPage(context, const AllFarmsScreen(followedOnly: true)),
              ),
              if (store.role == UserRole.farmer)
                MenuRow(
                  title: 'Your Farm Profile',
                  subtitle: store.ownFarm.name,
                  icon: Icons.storefront_outlined,
                  onTap: () => openPage(context, const FarmEditorScreen()),
                ),
              MenuRow(
                title: 'Help & Support',
                subtitle: 'Frequently asked questions and contact hub',
                icon: Icons.help_outline_rounded,
                onTap: () => openPage(context, const ContactScreen()),
              ),
              MenuRow(
                title: 'Password & Security',
                icon: Icons.lock_outline_rounded,
                onTap: () => openPage(
                  context,
                  store.isDemo
                      ? const GuestAccountPrompt(title: 'Password & Security')
                      : const SecurityScreen(),
                ),
              ),
            ],

            MenuRow(
              title: 'Farmers markets',
              subtitle: 'Locations and opening hours',
              icon: Icons.storefront_outlined,
              onTap: () => openPage(context, const MarketDirectory()),
            ),
            MenuRow(
              title: 'About HarvestHub',
              subtitle: 'Our story and local farming',
              icon: Icons.eco_outlined,
              onTap: () => openPage(context, const AboutScreen()),
            ),
            MenuRow(
              title: 'Notifications',
              subtitle: 'Order, pickup and stock updates',
              icon: Icons.notifications_outlined,
              onTap: () => openPage(context, const NotificationsScreen()),
            ),
            const SectionHeader('Theme & Display'),
            Builder(
              builder: (context) {
                return MenuRow(
                  title: isDark ? 'Dark Theme' : 'Light Theme',
                  subtitle: isDark
                      ? 'Deep emerald dark mode enabled'
                      : 'Lush natural cream light mode enabled',
                  icon: isDark
                      ? Icons.dark_mode_outlined
                      : Icons.light_mode_outlined,
                  trailing: Switch.adaptive(
                    value: isDark,
                    activeTrackColor: palette.green.withValues(alpha: 0.5),
                    activeThumbColor: palette.green,
                    onChanged: (_) => ThemeReveal.toggle(context),
                  ),
                  onTap: () => ThemeReveal.toggle(context),
                );
              },
            ),
            const SizedBox(height: 18),

            // Soft Red Logout Button matching reference
            Material(
              color: const Color(0xFFEF4444).withValues(alpha: 0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.25),
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                onTap: () async {
                  if (store.isDemo) {
                    store.requestSignIn();
                    return;
                  }
                  if (await confirmAction(
                    context,
                    title: 'Sign out?',
                    message: 'End your session and return to sign in.',
                    action: 'Sign out',
                  )) {
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      if (store.live) {
                        store.signOut();
                      } else {
                        onExit();
                      }
                    }
                  }
                },
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                title: Text(
                  store.isDemo ? 'Sign in / Create account' : 'Logout',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statPill(
    IconData icon,
    Color iconColor,
    String count,
    String label,
    VoidCallback onTap,
    HarvestPalette palette,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 4),
          Text(
            count,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w900,
              fontSize: 16,
              color: palette.ink,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: palette.muted,
            ),
          ),
        ],
      ),
    );
  }
}
