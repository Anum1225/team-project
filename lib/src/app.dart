import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'dart:async';

import 'features/common/notifications/notifications.dart';
import 'features/customer/customer.dart';
import 'features/customer/widgets/customer_style.dart';
import 'features/authentication/email_security.dart';
import 'features/common/management/operations.dart';
import 'features/customer/ai_assistant/assistant.dart';
import 'features/authentication/authentication.dart';
import 'features/common/shared/components.dart';
import 'features/common/data/models.dart';
import 'features/authentication/onboarding/onboarding.dart';
import 'features/common/orders/orders.dart';
import 'features/common/data/store.dart';
import 'features/common/data/firebase_store.dart';
import 'features/common/data/guest_store.dart';
import 'features/common/profile/profile.dart';
import 'features/common/shared/theme.dart';
import 'features/common/shared/theme_reveal.dart';
import 'features/common/shared/harvest_sprout.dart';

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({
    super.key,
    this.initialRole,
    this.store,
    this.skipStartup = false,
    this.initialOnboardingSeen = false,
    this.guestCatalogLoader,
  });

  final UserRole? initialRole;
  final HarvestStore? store;
  final bool skipStartup;
  final bool initialOnboardingSeen;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>)?
  guestCatalogLoader;

  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  late final HarvestStore store = widget.store ?? FirebaseStore();
  late bool preview = widget.initialRole != null;
  late bool ready = widget.skipStartup;
  late bool seenOnboarding = widget.skipStartup || widget.initialOnboardingSeen;
  GuestStore? guest;
  bool demo = false;

  void openDemo() {
    if (guest == null) {
      guest = widget.guestCatalogLoader == null
          ? GuestStore(onSignIn: leaveDemo)
          : GuestStore(
              onSignIn: leaveDemo,
              loadPage: widget.guestCatalogLoader!,
            );
      guest!.addListener(_onStore);
    }
    setState(() => demo = true);
    unawaited(guest!.refresh());
  }

  void leaveDemo() {
    setState(() {
      demo = false;
      seenOnboarding = true;
    });
  }

  void finishOnboarding() {
    setState(() => seenOnboarding = true);
    SharedPreferences.getInstance().then(
      (prefs) => prefs.setBool('harvesthub_onboarding_seen', true),
    );
  }

  @override
  void initState() {
    super.initState();
    if (!store.live && widget.initialRole != null) {
      store.role = widget.initialRole!;
    }
    store.addListener(_onStore);
  }

  void _onStore() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    store.removeListener(_onStore);
    guest?.removeListener(_onStore);
    guest?.dispose();
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _roleApp(context);
  }

  Widget _roleApp(BuildContext context) => HarvestScope(
    store: demo ? guest! : store,
    child: ThemeReveal(
      builder: (mode, wrap) => MaterialApp(
        key: ValueKey(
          demo
              ? 'guest'
              : store.live
              ? '${store.authenticated}:${store.emailVerificationPending}:${store.role}'
              : 'preview',
        ),
        title: 'HarvestHub',
        debugShowCheckedModeBanner: false,
        theme: demo || store.role == UserRole.customer
            ? customerTheme(Harvest.theme)
            : Harvest.theme,
        darkTheme: demo || store.role == UserRole.customer
            ? customerTheme(Harvest.darkTheme)
            : Harvest.darkTheme,
        themeMode: mode,
        themeAnimationDuration: Duration.zero,
        builder: (context, child) => wrap(
          ColoredBox(
            color: Harvest.colors(context).canvas,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: child!,
              ),
            ),
          ),
        ),
        home: demo
            ? AppShell(key: const ValueKey('guest'), onExit: leaveDemo)
            : !ready
            ? StartupScreen(onReady: () => setState(() => ready = true))
            : store.live && store.emailVerificationPending
            ? EmailCodeScreen(onCancel: store.signOut)
            : (!seenOnboarding && !(store.live ? store.authenticated : preview))
            ? OnboardingScreen(onFinish: finishOnboarding)
            : (store.live ? store.authenticated : preview)
            ? AppShell(
                key: ValueKey(store.role),
                onExit: () {
                  if (store.live) {
                    store.signOut();
                  } else {
                    setState(() => preview = false);
                  }
                },
              )
            : store.live && store.loading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : AuthScreen(role: UserRole.customer, onDemo: openDemo),
      ),
    ),
  );
}

/// Bespoke Seed-to-Sprout Startup Experience (Pure Botanical Animation, 2.6s)
class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key, required this.onReady});
  final VoidCallback onReady;

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _seedFade;
  late final Animation<double> _seedScale;
  late final Animation<double> _rippleProgress;
  late final Animation<double> _leafGrowth;
  late final Animation<double> _wordmarkReveal;
  late final Animation<double> _taglineFade;
  late final Animation<double> _glowPulse;
  bool _readyDispatched = false;

  @override
  void initState() {
    super.initState();
    // 2.6-second cinematic progression giving users ample time to enjoy the blooming sequence
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000),
    );

    // 0ms - 500ms: Golden seed emerges and settles in soil
    _seedFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.02, 0.20, curve: Curves.easeOut),
    );
    _seedScale = Tween<double>(begin: 0.30, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.02, 0.26, curve: Curves.easeOutBack),
      ),
    );

    // 400ms - 1000ms: Concentric soil ripples pulse outward
    _rippleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.48, curve: Curves.easeOutCubic),
    );

    // 600ms - 1800ms: Symmetrical botanical leaves unfurl & wheat ear blooms
    _leafGrowth = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.24, 0.72, curve: Curves.easeOutCubic),
    );

    // 1400ms - 2100ms: Editorial serif wordmark reveals upward
    _wordmarkReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.54, 0.82, curve: Curves.easeOutCubic),
    );

    // 1800ms - 2400ms: Tagline & certified local badge
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.70, 0.94, curve: Curves.easeOut),
    );

    _glowPulse = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_readyDispatched) {
        _readyDispatched = true;
        widget.onReady();
      }
    });

    _controller.forward();

    // Background asset pre-caching
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final name in [
        'farm',
        'honey',
        'market',
        'potatoes',
        'strawberries',
        'tomatoes',
        'pears',
        'corn',
        'eggs',
        'spinach',
      ]) {
        precacheImage(AssetImage('assets/images/$name.jpg'), context).ignore();
      }
    });
  }

  void _finishNow() {
    if (!_readyDispatched && mounted) {
      _readyDispatched = true;
      widget.onReady();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return Scaffold(
        backgroundColor: const Color(0xFF14241B),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeedMark(size: 72),
              const SizedBox(height: 24),
              Text(
                'HarvestHub',
                style: Harvest.editorial(40, color: const Color(0xFFF2EFE9)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fresh from farms. Closer to you.',
                style: TextStyle(
                  color: Color(0xFFB8B0A2),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              HarvestButton(
                label: 'Get Started',
                color: const Color(0xFF3D7A44),
                onPressed: _finishNow,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/farm_produce_crate.jpg',
            fit: BoxFit.cover,
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF04170F).withValues(alpha: 0.65),
                  const Color(0xFF08281C).withValues(alpha: 0.45),
                  const Color(0xFF061A12).withValues(alpha: 0.85),
                ],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                // Top-right quick skip button
                // Positioned(
                //   top: 16,
                //   right: 20,
                //   child: TextButton.icon(
                //     onPressed: _finishNow,
                //     style: TextButton.styleFrom(
                //       foregroundColor: const Color(0xFFF2EFE9)
                //           .withValues(alpha: 0.90),
                //       backgroundColor: Colors.black.withValues(alpha: 0.35),
                //       padding: const EdgeInsets.symmetric(
                //         horizontal: 14,
                //         vertical: 8,
                //       ),
                //       shape: RoundedRectangleBorder(
                //         borderRadius: BorderRadius.circular(20),
                //         side: BorderSide(
                //           color: Colors.white.withValues(alpha: 0.2),
                //         ),
                //       ),
                //     ),
                //     icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                //     label: const Text(
                //       'Skip',
                //       style: TextStyle(
                //         fontFamily: 'Manrope',
                //         fontSize: 12,
                //         fontWeight: FontWeight.w700,
                //         letterSpacing: 0.4,
                //       ),
                //     ),
                //   ),
                // ),

                // Animated central stage
                Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Concentric glowing soil ripples & pure botanical sprout animation
                        SizedBox(
                          width: 180,
                          height: 160,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // Ambient radiating aura ripples
                              if (_rippleProgress.value > 0) ...[
                                Opacity(
                                  opacity: ((1.0 - _rippleProgress.value) * 0.7)
                                      .clamp(0.0, 1.0),
                                  child: Container(
                                    width: 60 + (_rippleProgress.value * 95),
                                    height: 60 + (_rippleProgress.value * 95),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFFE8A93B)
                                            .withValues(alpha: 0.45),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF5C8A3A)
                                              .withValues(alpha: 0.25),
                                          blurRadius: 28,
                                          spreadRadius: 4,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Opacity(
                                  opacity: ((1.0 - _rippleProgress.value) * 0.5)
                                      .clamp(0.0, 1.0),
                                  child: Container(
                                    width: 40 + (_rippleProgress.value * 135),
                                    height: 40 + (_rippleProgress.value * 135),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: const Color(0xFF8FC494)
                                            .withValues(alpha: 0.35),
                                        width: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],

                              // Central growing sprout with glowing halo (Pure vector animation - no app logo)
                              Transform.scale(
                                scale: _seedScale.value,
                                child: Opacity(
                                  opacity: _seedFade.value,
                                  child: Container(
                                    width: 124,
                                    height: 124,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      gradient: const RadialGradient(
                                        center: Alignment(-0.35, -0.45),
                                        radius: 1.1,
                                        colors: [
                                          Color(0xFF2F8050),
                                          Color(0xFF12482F),
                                          Color(0xFF092D20),
                                        ],
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFFE8C06A),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE8A93B)
                                              .withValues(
                                                alpha:
                                                    0.35 *
                                                    _glowPulse.value.clamp(
                                                      0.5,
                                                      1.0,
                                                    ),
                                              ),
                                          blurRadius: 40,
                                          spreadRadius: 6,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: CustomPaint(
                                        size: const Size(92, 92),
                                        painter: HarvestSproutPainter(
                                          progress: _leafGrowth.value,
                                          color: const Color(0xFFBDEBC0),
                                          accentColor: const Color(0xFFFFCA65),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 22),

                        // Masked wordmark reveal matching HarvestHub branding
                        ClipRect(
                          child: Align(
                            alignment: Alignment.topCenter,
                            heightFactor: _wordmarkReveal.value,
                            child: Opacity(
                              opacity: _wordmarkReveal.value,
                              child: Column(
                                children: [
                                  RichText(
                                    text: TextSpan(
                                      children: [
                                        TextSpan(
                                          text: 'Harvest',
                                          style: Harvest.editorial(
                                            44,
                                            color: const Color(0xFFF2EFE9),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'H',
                                          style: Harvest.editorial(
                                            44,
                                            color: const Color(0xFFE8A93B),
                                          ),
                                        ),
                                        TextSpan(
                                          text: 'ub',
                                          style: Harvest.editorial(
                                            44,
                                            color: const Color(0xFFF2EFE9),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8A93B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'FRESH FROM FARMS',
                                        style: TextStyle(
                                          fontFamily: 'Manrope',
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 3.2,
                                          color: const Color(0xFFE8A93B)
                                              .withValues(alpha: 0.95),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        width: 4,
                                        height: 4,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFE8A93B),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tagline with upward glide
                        Opacity(
                          opacity: _taglineFade.value,
                          child: Transform.translate(
                            offset: Offset(0, 14 * (1.0 - _taglineFade.value)),
                            child: Column(
                              children: [
                                const Text(
                                  'Fresh from Farms, Good for You',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.3,
                                    color: Color(0xFFD4E5D8),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8A93B)
                                        .withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(0xFFE8A93B)
                                          .withValues(alpha: 0.40),
                                      width: 1,
                                    ),
                                  ),
                                  child: const Text(
                                    '✦ FRESH FROM FARMS, CLOSER TO YOU ✦',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      color: Color(0xFFFDE68A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom timeline indicator bar
                Positioned(
                  bottom: 24,
                  left: 40,
                  right: 40,
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) => ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: _controller.value,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF8FC494),
                        ),
                        minHeight: 2.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Pure Vector Botanical Seed-to-Sprout Growth Painter (No raster image)
class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onExit});
  final VoidCallback onExit;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final Map<int, Widget> pages = {};
  StreamSubscription<RemoteMessage>? _foregroundMessages, _openedMessages;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !HarvestScope.of(context).live || Firebase.apps.isEmpty) {
        return;
      }
      _foregroundMessages = FirebaseMessaging.onMessage.listen((message) async {
        final prefs = await SharedPreferences.getInstance();
        if (!mounted ||
            prefs.getBool(
                  'harvesthub_push_enabled_${HarvestScope.of(context).account.id}',
                ) !=
                true) {
          return;
        }
        final notification = message.notification;
        if (notification != null) {
          notice(
            context,
            [
              notification.title,
              notification.body,
            ].whereType<String>().join(' · '),
          );
        }
      });
      _openedMessages = FirebaseMessaging.onMessageOpenedApp.listen((_) {
        if (mounted) openPage(context, const NotificationsScreen());
      });
      try {
        final initial = await FirebaseMessaging.instance.getInitialMessage();
        if (mounted && initial != null) {
          openPage(context, const NotificationsScreen());
        }
      } on FirebaseException {
        // Opening the app remains available if messaging is temporarily down.
      }
    });
  }

  @override
  void dispose() {
    _foregroundMessages?.cancel();
    _openedMessages?.cancel();
    super.dispose();
  }

  void select(int value) {
    HapticFeedback.selectionClick();
    setState(() => index = value);
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final role = store.role;

    final labels = switch (role) {
      UserRole.customer => [
        'Home',
        'Explore',
        'Assistant',
        'Orders',
        'Profile',
      ],
      UserRole.farmer => [
        'Dashboard',
        'Products',
        'Orders',
        'Reports',
        'Profile',
      ],
      UserRole.admin => ['Dashboard', 'Users', 'Catalog', 'Orders', 'More'],
    };

    final icons = switch (role) {
      UserRole.customer => [
        Icons.home_rounded,
        Icons.spa_outlined,
        Icons.eco_rounded,
        Icons.receipt_long_outlined,
        Icons.person_outline_rounded,
      ],
      UserRole.farmer => [
        Icons.dashboard_outlined,
        Icons.inventory_2_outlined,
        Icons.receipt_long_outlined,
        Icons.analytics_outlined,
        Icons.person_outline_rounded,
      ],
      UserRole.admin => [
        Icons.analytics_outlined,
        Icons.people_outline_rounded,
        Icons.category_outlined,
        Icons.receipt_long_outlined,
        Icons.more_horiz_rounded,
      ],
    };

    Widget page(int value) => switch (role) {
      UserRole.customer => switch (value) {
        0 => HomeScreen(
          onExplore: () => select(1),
          onAssistant: () => select(2),
          onProfile: () => select(4),
        ),
        1 => const ExploreScreen(),
        2 => const AssistantScreen(),
        3 => const OrdersScreen(),
        _ => ProfileScreen(onExit: widget.onExit),
      },
      UserRole.farmer => switch (value) {
        0 => DashboardScreen(
          onProducts: () => select(1),
          onOrders: () => select(2),
        ),
        1 => const InventoryScreen(),
        2 => const OrdersScreen(),
        3 => const ReportsScreen(),
        _ => ProfileScreen(onExit: widget.onExit),
      },
      UserRole.admin => switch (value) {
        0 => DashboardScreen(
          onProducts: () => select(2),
          onOrders: () => select(3),
        ),
        1 => const UsersScreen(),
        2 => const InventoryScreen(),
        3 => const OrdersScreen(),
        _ => ProfileScreen(onExit: widget.onExit),
      },
    };

    if (store.live && !store.authenticated) return const SizedBox.shrink();
    pages.putIfAbsent(index, () => page(index));

    return PopScope(
      canPop: index == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && index != 0) select(0);
      },
      child: Scaffold(
        backgroundColor: Harvest.colors(context).cream,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              if (store.isDemo)
                Material(
                  color: Harvest.colors(context).paleLeaf,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Demo · Browse the live catalog',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                        TextButton(
                          onPressed: store.requestSignIn,
                          child: const Text('Sign in'),
                        ),
                      ],
                    ),
                  ),
                ),
              if ((store.live || store.isDemo) &&
                  (store.loading || store.error != null || store.hasMore))
                const DataStatusBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: MediaQuery.disableAnimationsOf(context)
                      ? Duration.zero
                      : const Duration(milliseconds: 280),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) {
                    return FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.025),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    );
                  },
                  child: KeyedSubtree(
                    key: ValueKey<int>(index),
                    child: pages[index] ?? page(index),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Floating HarvestHub dock with a measured, animated active capsule.
        bottomNavigationBar: Container(
          color: Colors.transparent,
          child: SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(14, 4, 14, 8),
              height: 68,
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xFF10281B)
                    : const Color(0xFF123522),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF07170E).withValues(
                      alpha: Theme.of(context).brightness == Brightness.dark
                          ? 0.52
                          : 0.24,
                    ),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final itemWidth = constraints.maxWidth / labels.length;
                  final noMotion = MediaQuery.disableAnimationsOf(context);
                  return Stack(
                    children: [
                      AnimatedPositioned(
                        duration: noMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 360),
                        curve: Curves.easeOutCubic,
                        left: itemWidth * index + 4,
                        top: 6,
                        width: itemWidth - 8,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF2A7850), Color(0xFF1A5738)],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.17),
                            ),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x3325A363),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Row(
                        children: List.generate(labels.length, (i) {
                          final selected = index == i;
                          return Expanded(
                            child: Semantics(
                              selected: selected,
                              button: true,
                              label: labels[i],
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: () => select(i),
                                  child: SizedBox(
                                    height: 68,
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        AnimatedScale(
                                          scale: selected ? 1.08 : 1,
                                          duration: noMotion
                                              ? Duration.zero
                                              : const Duration(
                                                  milliseconds: 220,
                                                ),
                                          curve: Curves.easeOutBack,
                                          child: Icon(
                                            icons[i],
                                            size: 22,
                                            color: Colors.white.withValues(
                                              alpha: selected ? 1 : 0.68,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 11,
                                          ),
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            child: AnimatedDefaultTextStyle(
                                              duration: noMotion
                                                  ? Duration.zero
                                                  : const Duration(
                                                      milliseconds: 180,
                                                    ),
                                              style: TextStyle(
                                                fontFamily: 'Manrope',
                                                fontSize: 10,
                                                height: 1.1,
                                                letterSpacing: 0,
                                                fontWeight: selected
                                                    ? FontWeight.w800
                                                    : FontWeight.w600,
                                                color: Colors.white.withValues(
                                                  alpha: selected ? 1 : 0.72,
                                                ),
                                              ),
                                              child: Text(labels[i]),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
