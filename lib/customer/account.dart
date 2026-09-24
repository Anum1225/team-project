import 'package:flutter/material.dart';

import 'store.dart';
import 'ui.dart';
import 'app.dart';
import 'catalog.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => ListView(
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
            const Tag('CUSTOMER · DEMO'),
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
              () => openPage(context, const PasswordScreen()),
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
              title: const Text('Leave the demo?'),
              content: const Text(
                'Your demo basket, saved products and orders will be cleared.',
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
            store.reset();
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => WelcomeScreen(store: store)),
              (_) => false,
            );
          }
        },
        icon: const Icon(Icons.logout),
        label: const Text('Log out of demo'),
      ),
      const SizedBox(height: 24),
      const Text(
        'HarvestHub · Grown with care\nCustomer preview v1.0',
        textAlign: TextAlign.center,
        style: TextStyle(color: muted, height: 1.8, fontSize: 12),
      ),
    ],
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

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.profile.name);
  late final email = TextEditingController(text: widget.store.profile.email);
  late final phone = TextEditingController(text: widget.store.profile.phone);
  late final address = TextEditingController(
    text: widget.store.profile.address,
  );
  @override
  void dispose() {
    for (final c in [name, email, phone, address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Edit profile',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Heading(
            'Make yourself at home',
            subtitle: 'Keep your contact information up to date.',
          ),
          field(name, 'Full name'),
          const SizedBox(height: 18),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
            validator: emailValidator,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Mobile phone number'),
            validator: phoneValidator,
          ),
          const SizedBox(height: 18),
          field(address, 'Address', maxLines: 3),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              if (!form.currentState!.validate()) {
                return;
              }
              widget.store.updateProfile(
                CustomerProfile(
                  name: name.text.trim(),
                  email: email.text.trim(),
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                ),
              );
              Navigator.pop(context);
              toast(context, 'Profile updated for this demo session');
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    ),
  );
}

class PasswordScreen extends StatefulWidget {
  const PasswordScreen({super.key});
  @override
  State<PasswordScreen> createState() => _PasswordScreenState();
}

class _PasswordScreenState extends State<PasswordScreen> {
  final form = GlobalKey<FormState>();
  final current = TextEditingController(),
      next = TextEditingController(),
      confirm = TextEditingController();
  bool hidden = true;
  @override
  void dispose() {
    current.dispose();
    next.dispose();
    confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Change password',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Heading(
            'Keep your account secure',
            subtitle: 'Choose a password with at least 8 characters.',
          ),
          const Surface(
            color: lime,
            child: Text(
              'Preview only. Password changes require live authentication.',
              style: TextStyle(color: green),
            ),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: current,
            obscureText: hidden,
            decoration: const InputDecoration(labelText: 'Current password'),
            validator: requiredValue,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: next,
            obscureText: hidden,
            decoration: const InputDecoration(labelText: 'New password'),
            validator: (v) => (v ?? '').length < 8
                ? 'Use at least 8 characters'
                : v == current.text
                ? 'Choose a different password'
                : null,
          ),
          const SizedBox(height: 18),
          TextFormField(
            controller: confirm,
            obscureText: hidden,
            decoration: const InputDecoration(
              labelText: 'Confirm new password',
            ),
            validator: (v) =>
                v != next.text ? 'Passwords do not match' : requiredValue(v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Show passwords'),
            value: !hidden,
            onChanged: (v) => setState(() => hidden = !v),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                toast(
                  context,
                  'Form validated. No password was changed; authentication is not connected.',
                );
              }
            },
            child: const Text('Update password'),
          ),
        ],
      ),
    ),
  );
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      title: 'Notifications',
      actions: [
        TextButton(
          onPressed: store.unread == 0 ? null : store.markRead,
          child: const Text('Read all'),
        ),
      ],
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Heading(
            'A little news from the farm',
            subtitle: 'Your order and pickup updates, all in one place.',
          ),
          const Surface(
            color: lime,
            child: Text(
              'In-app demo updates. Live restock and push notifications are not connected.',
              style: TextStyle(color: green),
            ),
          ),
          const SizedBox(height: 20),
          if (store.notices.isEmpty)
            const EmptyState(
              Icons.notifications_none,
              'All quiet for now',
              'Your next order or pickup update will appear here.',
            ),
          ...store.notices.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Surface(
                color: n.read ? Colors.white : const Color(0xFFF0F4E8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      n.read
                          ? Icons.mark_email_read_outlined
                          : Icons.notifications_active_outlined,
                      color: green,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: green,
                            ),
                          ),
                          const SizedBox(height: 7),
                          Text(
                            n.message,
                            style: const TextStyle(height: 1.6, color: muted),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  final List<({bool user, String text})> messages = [
    (
      user: false,
      text: 'Hello, fresh-food friend! 🌱 I can help with produce storage, seasonal ideas, simple salads, and the sample farms in HarvestHub. What is on your mind?',
    ),
  ];
  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  String answer(String question) {
    final q = question.toLowerCase();
    if (q.contains('stock') || q.contains('available')) {
      return 'In our demo catalog: ${products.where((p) => widget.store.stock(p) > 0).map((p) => '${p.name} (${widget.store.stock(p)} available)').join(', ')}. Check the product page before adding to your basket.';
    }
    if (q.contains('pickup') || q.contains('timing')) {
      return 'Choose a pickup window for each farm during checkout. The sample slots are ${pickupSlots().join('; ')}. Open Orders → View details → Manage booking to change or cancel a pickup.';
    }
    if (q.contains('farmer') || q.contains('market')) {
      return 'Meet ${farmers.map((f) => '${f.name} at ${f.market} in ${f.location}').join('; ')}. Open a farm profile to browse its products and follow it.';
    }
    if (q.contains('vitamin') || q.contains('fruit')) {
      return 'Oranges, guavas, strawberries, and kiwifruit are familiar fruit choices that contain vitamin C. Choose a variety of seasonal produce as part of your everyday meals.';
    }
    if (q.contains('tomato') || q.contains('storage') || q.contains('store')) {
      return 'Keep unripe whole tomatoes at room temperature, away from direct sun. Refrigerate ripe tomatoes if you need them to last longer, and refrigerate cut tomatoes in a covered container.';
    }
    if (q.contains('spinach')) {
      return 'Spinach is a leafy green that contributes fiber and nutrients such as folate and vitamin K. Add washed leaves to salads, soups, or a quick sauté.';
    }
    if (q.contains('salad')) {
      return 'Try a colorful bowl of cucumber, tomatoes, grated carrots, and leafy greens. Finish with lemon and olive oil. Add cooked chickpeas if you would like a more filling bowl.';
    }
    if (q.contains('season')) {
      return 'Seasonal produce varies by place and weather. Browse local farm listings and ask your grower what was recently harvested. Our sample catalog includes carrots, tomatoes, and strawberries.';
    }
    return 'I use a small set of prepared answers. Try asking about tomato storage, vitamin C fruits, spinach, salad ideas, available stock, local farmers, or pickup timings.';
  }

  void send(String value) {
    if (value.trim().isEmpty) {
      return;
    }
    setState(() {
      messages.add((user: true, text: value.trim()));
      messages.add((user: false, text: answer(value)));
      input.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.animateTo(
          scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Farm assistant',
    child: Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Surface(
            color: lime,
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: green),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your pocket-sized produce guide\nPrepared answers · General food information',
                    style: TextStyle(color: green, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            itemCount: messages.length,
            itemBuilder: (context, i) {
              final m = messages[i];
              return Align(
                alignment: m.user
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 540),
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: m.user ? green : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    m.text,
                    style: TextStyle(
                      color: m.user ? Colors.white : green,
                      height: 1.65,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            children:
                [
                      'How to store tomatoes?',
                      'Salad ideas',
                      'What is in stock?',
                      'Pickup timings',
                    ]
                    .map(
                      (s) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ActionChip(
                          label: Text(s),
                          onPressed: () => send(s),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: input,
                  onSubmitted: send,
                  decoration: const InputDecoration(
                    hintText: 'Ask something fresh…',
                  ),
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Send message',
                onPressed: () => send(input.text),
                icon: const Icon(Icons.arrow_upward),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

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

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.profile.name);
  late final email = TextEditingController(text: widget.store.profile.email);
  final message = TextEditingController();
  String subject = 'General question';
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Contact us',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Heading(
            'Let’s talk fresh',
            subtitle:
                'A question, an idea, or a little feedback? We are listening.',
          ),
          const Surface(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.mail_outline, color: green),
                  title: Text('Email support'),
                  subtitle: Text('Support email will be added before launch'),
                ),
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: green),
                  title: Text('Phone'),
                  subtitle: Text('Support number will be added before launch'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: green),
                  title: Text('Office'),
                  subtitle: Text('Office address will be added before launch'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Heading('Send a little note'),
          field(name, 'Your name'),
          const SizedBox(height: 16),
          TextFormField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email address'),
            validator: emailValidator,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: subject,
            decoration: const InputDecoration(labelText: 'Subject'),
            items: [
              'General question',
              'Order help',
              'Pickup help',
              'Feedback',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) => subject = v!,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: message,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Your message'),
            validator: (v) => (v ?? '').trim().length < 10
                ? 'Please enter at least 10 characters'
                : null,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                toast(
                  context,
                  'Preview only: your message has not been sent. Support will be connected before launch.',
                );
              }
            },
            child: const Text('Preview feedback submission'),
          ),
        ],
      ),
    ),
  );
}
