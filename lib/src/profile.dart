import 'package:flutter/material.dart';

import 'auth.dart';
import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'operations.dart';
import 'orders.dart';
import 'theme.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.onExit});
  final VoidCallback onExit;
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final account = store.account;
    final admin = store.role == UserRole.admin;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        PageHeading(
          admin ? 'The bigger\npicture.' : 'A little\nabout you.',
          eyebrow: admin ? 'Platform & settings' : 'Your corner of the market',
        ),
        Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Harvest.sage,
              child: Text(account.name[0], style: Harvest.editorial(30)),
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    account.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    account.email,
                    style: const TextStyle(color: Harvest.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Eyebrow(account.role.label),
                ],
              ),
            ),
          ],
        ),
        const SectionHeader('Account'),
        MenuRow(
          title: 'Personal details',
          subtitle: 'Name, phone & address',
          icon: Icons.person_outline,
          onTap: () => openPage(context, const ProfileEditorScreen()),
        ),
        if (store.role == UserRole.farmer)
          MenuRow(
            title: 'Your farm profile',
            subtitle: store.ownFarm.name,
            icon: Icons.spa_outlined,
            onTap: () => openPage(context, const FarmEditorScreen()),
          ),
        MenuRow(
          title: 'Password & security',
          icon: Icons.lock_outline,
          onTap: () => openPage(context, const SecurityScreen()),
        ),
        if (admin) ...[
          const SectionHeader('Manage HarvestHub'),
          MenuRow(
            title: 'Categories',
            subtitle: 'Keep the market easy to browse',
            icon: Icons.category_outlined,
            onTap: () => openPage(context, const CategoriesScreen()),
          ),
          MenuRow(
            title: 'Platform reports',
            subtitle: 'Orders, sales & active farmers',
            icon: Icons.bar_chart_outlined,
            onTap: () => openPage(
              context,
              const HarvestPage(
                title: 'Platform reports',
                child: ReportsScreen(),
              ),
            ),
          ),
        ],
        if (store.role == UserRole.customer) ...[
          const SectionHeader('Your activity'),
          MenuRow(
            title: 'Your orders',
            icon: Icons.receipt_long_outlined,
            onTap: () => openPage(
              context,
              const HarvestPage(title: 'Your orders', child: OrdersScreen()),
            ),
          ),
          MenuRow(
            title: 'Saved for later',
            subtitle: '${store.saved.length} favourites',
            icon: Icons.favorite_border,
            onTap: () => openPage(context, const WishlistScreen()),
          ),
        ],
        const SectionHeader('Good to know'),
        MenuRow(
          title: 'About HarvestHub',
          icon: Icons.eco_outlined,
          onTap: () => openPage(context, const AboutScreen()),
        ),
        MenuRow(
          title: 'Get in touch',
          icon: Icons.chat_bubble_outline,
          onTap: () => openPage(context, const ContactScreen()),
        ),
        const SizedBox(height: 24),
        if (!store.live)
          const InfoNote(
            'You’re exploring a design preview. Sample data and changes last until the app is restarted.',
          ),
        if (!store.live)
          TextButton.icon(
            onPressed: () => openPage(context, const StateGalleryScreen()),
            icon: const Icon(Icons.layers_outlined, size: 18),
            label: const Text('Preview interface states'),
          ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async {
            if (await confirmAction(
              context,
              title: 'Sign out?',
              message: 'End your session and return to the welcome screen.',
              action: 'Sign out',
            )) {
              if (context.mounted) {
                Navigator.of(context).popUntil((r) => r.isFirst);
                onExit();
              }
            }
          },
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign out'),
        ),
      ],
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
      description = TextEditingController();
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
  }

  @override
  void dispose() {
    for (final c in [name, location, market, description]) {
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
                    final result = await HarvestScope.of(context)
                        .changePassword(old.text, password.text);
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
        const Eyebrow('HarvestHub · Harvest Living'),
        const SizedBox(height: 8),
        const Text(
          'Fresh from farms. Closer to you.',
          style: TextStyle(color: Harvest.muted),
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
                    final result = await HarvestScope.of(context)
                        .sendFeedback(email.text, message.text);
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
                          decoration: const BoxDecoration(
                            color: Harvest.sage,
                            borderRadius: Harvest.radius,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              Container(height: 16, color: Harvest.border),
                              const SizedBox(height: 12),
                              Container(height: 12, color: Harvest.sage),
                              const SizedBox(height: 16),
                              Container(height: 12, color: Harvest.sage),
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
