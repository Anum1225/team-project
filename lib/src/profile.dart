import 'market_directory.dart';
import 'notifications.dart';
import 'location_picker.dart';
import 'package:flutter/material.dart';

import 'avatars.dart';
import 'auth.dart';
import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'operations.dart';
import 'orders.dart';
import 'reporting.dart';
import 'theme.dart';
import 'theme_reveal.dart';

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
                        : const ProfileEditorScreen(),
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
                title: 'My Addresses',
                subtitle: 'Manage your saved address and map location',
                icon: Icons.location_on_outlined,
                onTap: () => openPage(context, const ProfileEditorScreen()),
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
                onTap: () => openPage(context, const SecurityScreen()),
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
                  if (await confirmAction(
                    context,
                    title: 'Sign out?',
                    message: 'End your session and return to sign in.',
                    action: 'Sign out',
                  )) {
                    if (context.mounted) {
                      Navigator.of(context).popUntil((r) => r.isFirst);
                      onExit();
                    }
                  }
                },
                leading: const Icon(
                  Icons.logout_rounded,
                  color: Color(0xFFEF4444),
                  size: 22,
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
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

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, this.account});
  final Account? account;
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final a = widget.account ?? HarvestScope.of(context).account;
    name.text = a.name;
    phone.text = a.phone;
    address.text = a.address;
  }

  @override
  void dispose() {
    for (final c in [name, phone, address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return HarvestPage(
      title: 'Personal details',
      bottom: HarvestButton(
        label: 'Save changes',
        onPressed: store.busy
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                final original = widget.account ?? store.account;
                final a = Account(
                  id: original.id,
                  name: name.text.trim(),
                  email: original.email,
                  role: original.role,
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                  avatar: original.avatar,
                  active: original.active,
                );
                final result = await store.saveAccount(a);
                if (!context.mounted) return;
                if (result != null) {
                  notice(context, result, isError: true);
                  return;
                }
                Navigator.pop(context);
                notice(context, 'Your profile has been updated');
              },
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const PageHeading(
              'Make yourself\nat home.',
              subtitle: 'Keep your contact details up to date.',
            ),
            HarvestField(controller: name, label: 'Full name'),
            const SizedBox(height: 16),
            HarvestField(
              controller: phone,
              label: 'Mobile phone',
              keyboard: TextInputType.phone,
              validator: (v) =>
                  v == null || v.replaceAll(RegExp(r'\D'), '').length < 7
                  ? 'Enter a valid phone number.'
                  : null,
            ),
            const SizedBox(height: 16),
            HarvestField(controller: address, label: 'Address', lines: 3),
            const SizedBox(height: 24),
            InfoNote(
              'Account email: ${(widget.account ?? store.account).email}. Email is managed through Firebase Authentication.',
            ),
          ],
        ),
      ),
    );
  }
}

class FarmEditorScreen extends StatefulWidget {
  const FarmEditorScreen({super.key, this.farm});
  final Farm? farm;
  @override
  State<FarmEditorScreen> createState() => _FarmEditorScreenState();
}

class _FarmEditorScreenState extends State<FarmEditorScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      location = TextEditingController(),
      market = TextEditingController(),
      description = TextEditingController(),
      windows = TextEditingController();
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final f = widget.farm ?? HarvestScope.of(context).ownFarm;
    name.text = f.name;
    location.text = f.location;
    market.text = f.market;
    description.text = f.description;
    windows.text = f.pickupSlots.join("\n");
  }

  @override
  void dispose() {
    for (final c in [name, location, market, description, windows]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return HarvestPage(
      title: 'Your farm profile',
      bottom: HarvestButton(
        label: 'Save farm profile',
        onPressed: store.busy
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                final original = widget.farm ?? store.ownFarm;
                final f = Farm(
                  id: original.id,
                  owner: original.owner,
                  name: name.text.trim(),
                  location: location.text.trim(),
                  market: market.text.trim(),
                  description: description.text.trim(),
                  image: original.image,
                  pickupSlots: windows.text
                      .split('\n')
                      .map((v) => v.trim())
                      .where((v) => v.isNotEmpty)
                      .toSet()
                      .toList(),
                  latitude:
                      double.tryParse(location.text.split(',').first.trim()) ??
                      original.latitude,
                  longitude: location.text.split(',').length == 2
                      ? double.tryParse(location.text.split(',').last.trim())
                      : original.longitude,
                  active: original.active,
                );
                final result = await store.saveFarm(f);
                if (!context.mounted) return;
                if (result != null) {
                  notice(context, result, isError: true);
                  return;
                }
                Navigator.pop(context);
                notice(context, 'Farm profile updated');
              },
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Photo(
              (widget.farm ?? store.ownFarm).image,
              height: 180,
              width: double.infinity,
            ),
            const PageHeading('Tell your\nfarm’s story.'),
            HarvestField(controller: name, label: 'Farm or business name'),
            const SizedBox(height: 16),
            HarvestField(controller: location, label: 'Location'),
            Align(
              alignment: Alignment.centerRight,
              child: LocationPickerButton(
                onSelected: (value) => setState(() => location.text = value),
              ),
            ),
            HarvestField(
              controller: windows,
              label: 'Pickup windows (one per line, up to 20)',
              lines: 5,
              validator: (value) {
                final rows = (value ?? '')
                    .split('\n')
                    .where((s) => s.trim().isNotEmpty);
                return rows.length > 20 || rows.any((s) => s.length > 160)
                    ? 'Use up to 20 windows, each under 160 characters.'
                    : null;
              },
            ),
            const SizedBox(height: 16),
            HarvestField(controller: market, label: 'Market name'),
            const SizedBox(height: 16),
            HarvestField(
              controller: description,
              label: 'About your farm',
              lines: 5,
            ),
          ],
        ),
      ),
    );
  }
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final old = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  final form = GlobalKey<FormState>();
  bool submitted = false;
  @override
  void dispose() {
    for (final c in [old, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Password & security',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Keep your\naccount yours.',
            subtitle: 'Use a unique password with at least 8 characters.',
          ),
          TextFormField(
            controller: old,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Current password'),
            validator: requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) =>
                v == null || v.length < 8 ? 'Use at least 8 characters.' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmation,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            validator: (v) => v != password.text
                ? 'The passwords don’t match.'
                : requiredValidator(v),
          ),
          const SizedBox(height: 24),
          HarvestButton(
            label: 'Update password',
            onPressed: HarvestScope.of(context).busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    final result = await HarvestScope.of(
                      context,
                    ).changePassword(old.text, password.text);
                    if (!context.mounted) return;
                    if (result != null) {
                      notice(context, result, isError: true);
                    } else {
                      setState(() => submitted = true);
                    }
                  },
          ),
          if (submitted) ...[
            const SizedBox(height: 20),
            const InfoNote('Your password has been updated.', error: true),
          ],
        ],
      ),
    ),
  );
}

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Our story',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SeedMark(size: 46),
        const SizedBox(height: 24),
        const Eyebrow('Rooted in something good'),
        const SizedBox(height: 14),
        Text('Good food starts\ncloser to home.', style: Harvest.editorial(40)),
        const SizedBox(height: 24),
        const Photo(
          'market',
          height: 240,
          width: double.infinity,
          radius: 28,
          label: 'A colourful market of fresh produce',
        ),
        const SizedBox(height: 28),
        Text('A market with meaning.', style: Harvest.editorial(28)),
        const SizedBox(height: 14),
        const Text(
          'HarvestHub brings local farmers and everyday food lovers together. A place to discover what’s growing, meet the people who grow it, and make thoughtful choices for your table.',
        ),
        const PublishedContent(),
        const SectionHeader('Good for your community.'),
        const Text(
          'Every farm has a story. By making it easier to discover local growers, we help those stories reach a little further.',
        ),
        const SectionHeader('Simple by nature.'),
        const Text(
          'Fresh produce. Clear information. People you can get to know. We believe a good food experience starts with the essentials.',
        ),
        const SizedBox(height: 32),
        const Divider(),
        const SizedBox(height: 20),
        const Eyebrow('HarvestHub'),
        const SizedBox(height: 8),
        Text(
          'Fresh from farms. Closer to you.',
          style: TextStyle(color: Harvest.colors(context).muted),
        ),
      ],
    ),
  );
}

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), message = TextEditingController();
  bool sent = false;
  @override
  void dispose() {
    email.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Get in touch',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PublishedContent(contact: true),
          const PageHeading(
            'We’re all ears.',
            eyebrow: 'A conversation starts here',
            subtitle: 'A question, an idea, or something we could do better?',
          ),
          const InfoNote('Send your feedback to the HarvestHub team.'),
          const SizedBox(height: 28),
          HarvestField(
            controller: email,
            label: 'Your email address',
            keyboard: TextInputType.emailAddress,
            validator: emailValidator,
          ),
          const SizedBox(height: 16),
          HarvestField(controller: message, label: 'Your message', lines: 5),
          const SizedBox(height: 24),
          HarvestButton(
            label: 'Send feedback',
            icon: Icons.arrow_forward,
            onPressed: HarvestScope.of(context).busy || sent
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    final result = await HarvestScope.of(
                      context,
                    ).sendFeedback(email.text, message.text);
                    if (!context.mounted) return;
                    if (result != null) {
                      notice(context, result, isError: true);
                    } else {
                      setState(() => sent = true);
                    }
                  },
          ),
          if (sent) ...[
            const SizedBox(height: 24),
            const InfoNote('Thank you. Your feedback has been saved.'),
          ],
        ],
      ),
    ),
  );
}

class StateGalleryScreen extends StatefulWidget {
  const StateGalleryScreen({super.key});
  @override
  State<StateGalleryScreen> createState() => _StateGalleryScreenState();
}

class _StateGalleryScreenState extends State<StateGalleryScreen> {
  String state = 'Loading';
  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Interface states',
    child: ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const PageHeading(
          'Care in every state.',
          subtitle: 'A design reference for future service integration.',
        ),
        ChoiceRow(
          values: const [
            'Loading',
            'Empty',
            'Offline',
            'Error',
            'Unauthorized',
          ],
          selected: state,
          onSelected: (v) => setState(() => state = v),
        ),
        const SizedBox(height: 28),
        if (state == 'Loading')
          Semantics(
            label: 'Loading products',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Row(
                      children: [
                        Container(
                          width: 90,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Harvest.colors(context).paleLeaf,
                            borderRadius: Harvest.radius,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Container(
                                height: 16,
                                color: Harvest.colors(context).border,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                height: 12,
                                color: Harvest.colors(context).paleLeaf,
                              ),
                              const SizedBox(height: 16),
                              Container(
                                height: 12,
                                color: Harvest.colors(context).paleLeaf,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          )
        else
          EmptyState(
            title: switch (state) {
              'Empty' => 'Save something fresh.',
              'Offline' => 'You’re offline.',
              'Unauthorized' => 'This space is protected.',
              _ => 'Something didn’t grow right.',
            },
            message: switch (state) {
              'Empty' =>
                'Browse seasonal produce to keep your favourites close.',
              'Offline' => 'We’ll reconnect when your network returns.',
              'Unauthorized' =>
                'Sign in with the right account to access this area.',
              _ => 'We couldn’t load your products. Please try again.',
            },
            icon: switch (state) {
              'Empty' => Icons.favorite_border,
              'Offline' => Icons.wifi_off,
              'Unauthorized' => Icons.lock_outline,
              _ => Icons.error_outline,
            },
            action: 'Reset preview',
            onAction: () => setState(() => state = 'Loading'),
          ),
      ],
    ),
  );
}
