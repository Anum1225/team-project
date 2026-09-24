import 'package:flutter/material.dart';

import 'store.dart';
import 'ui.dart';
import 'catalog.dart';
import 'shopping.dart';
import 'account.dart';

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({super.key});
  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  final store = CustomerStore();
  @override
  void dispose() {
    store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'HarvestHub · Fresh from your community',
    debugShowCheckedModeBanner: false,
    theme: customerTheme(),
    home: WelcomeScreen(store: store),
  );
}

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
                        onPressed: () => openPage(
                          context,
                          AuthScreen(store: store, mode: 'Create account'),
                        ),
                        icon: const Icon(Icons.arrow_forward),
                        label: const Text('Get started'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () =>
                            openPage(context, AuthScreen(store: store)),
                        child: const Text('I already have an account'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => CustomerShell(store: store),
                          ),
                        ),
                        child: const Text('Explore customer demo'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'SCREEN PREVIEW · Sample data · No real payments',
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

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.store, this.mode = 'Sign in'});
  final CustomerStore store;
  final String mode;
  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      email = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController(),
      password = TextEditingController();
  bool hidden = true;
  @override
  void dispose() {
    for (final c in [name, email, phone, address, password]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final register = widget.mode == 'Create account';
    final reset = widget.mode == 'Reset password';
    return PageFrame(
      title: widget.mode,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Form(
              key: form,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.eco, color: green, size: 48),
                  const SizedBox(height: 22),
                  Heading(
                    reset
                        ? 'A fresh start'
                        : register
                        ? 'Join your local harvest'
                        : 'Welcome back',
                    subtitle: reset
                        ? 'Enter your account email to request a password reset.'
                        : 'A little closer to fresh, local food.',
                  ),
                  const Surface(
                    color: lime,
                    child: Text(
                      'Customer screen preview. Authentication is not connected yet; use Explore customer demo to try the shopping experience.',
                      style: TextStyle(color: green, height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (register) ...[
                    field(name, 'Full name'),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email address',
                      prefixIcon: Icon(Icons.mail_outline),
                    ),
                    validator: emailValidator,
                  ),
                  if (register) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Mobile phone number',
                      ),
                      validator: phoneValidator,
                    ),
                    const SizedBox(height: 16),
                    field(address, 'Address', maxLines: 2),
                  ],
                  if (!reset) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: password,
                      obscureText: hidden,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          tooltip: hidden ? 'Show password' : 'Hide password',
                          onPressed: () => setState(() => hidden = !hidden),
                          icon: Icon(
                            hidden
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                        ),
                      ),
                      validator: (v) => (v ?? '').length < 8
                          ? 'Use at least 8 characters'
                          : null,
                    ),
                  ],
                  if (!register && !reset)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => openPage(
                          context,
                          AuthScreen(
                            store: widget.store,
                            mode: 'Reset password',
                          ),
                        ),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () {
                      if (form.currentState!.validate()) {
                        toast(
                          context,
                          reset
                              ? 'Preview only: no reset email was sent. Authentication setup is pending.'
                              : 'Form validated. Live ${register ? 'registration' : 'sign in'} is not connected. Explore the demo below.',
                        );
                      }
                    },
                    child: Text(reset ? 'Request reset link' : widget.mode),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => CustomerShell(store: widget.store),
                      ),
                      (_) => false,
                    ),
                    child: const Text('Explore customer demo'),
                  ),
                  if (!reset)
                    TextButton(
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => AuthScreen(
                            store: widget.store,
                            mode: register ? 'Sign in' : 'Create account',
                          ),
                        ),
                      ),
                      child: Text(
                        register
                            ? 'Already have an account? Sign in'
                            : 'New here? Create an account',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String? requiredValue(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required' : null;
String? emailValidator(String? value) =>
    RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value?.trim() ?? '')
    ? null
    : 'Enter a valid email address';
String? phoneValidator(String? value) =>
    (value ?? '').replaceAll(RegExp(r'\D'), '').length < 10
    ? 'Enter a valid phone number'
    : null;
Widget field(
  TextEditingController controller,
  String label, {
  int maxLines = 1,
}) => TextFormField(
  controller: controller,
  maxLines: maxLines,
  decoration: InputDecoration(labelText: label),
  validator: requiredValue,
);

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
              const Padding(
                padding: EdgeInsets.only(right: 18),
                child: Tag('CUSTOMER DEMO'),
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
                    child: pages[selected],
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
