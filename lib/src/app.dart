import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'assistant.dart';
import 'auth.dart';
import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'operations.dart';
import 'orders.dart';
import 'store.dart';
import 'firebase_store.dart';
import 'profile.dart';
import 'theme.dart';

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({
    super.key,
    this.initialRole,
    this.store,
    this.skipStartup = false,
  });

  final UserRole? initialRole;
  final HarvestStore? store;
  final bool skipStartup;

  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  late final HarvestStore store = widget.store ?? FirebaseStore();
  late bool preview = widget.initialRole != null;
  late bool ready = widget.skipStartup;

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
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  void enter(UserRole role) {
    if (store.live) return;
    store.chooseRole(role);
    setState(() => preview = true);
  }

  @override
  Widget build(BuildContext context) => HarvestScope(
    store: store,
    child: MaterialApp(
      key: ValueKey(
        store.live ? '${store.authenticated}:${store.role}' : 'preview',
      ),
      title: 'HarvestHub · Harvest Living',
      debugShowCheckedModeBanner: false,
      theme: Harvest.theme,
      darkTheme: Harvest.darkTheme,
      themeMode: ThemeMode.light,
      builder: (context, child) => ColoredBox(
        color: Harvest.canvas,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 580),
            child: child!,
          ),
        ),
      ),
      home: !ready
          ? StartupScreen(onReady: () => setState(() => ready = true))
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
          : WelcomeScreen(
              onPreview: enter,
              onReplaySplash: () => setState(() => ready = false),
            ),
    ),
  );
}

/// Bespoke Seed-to-Sprout Splash Experience (Cinematic 0ms to 2500ms)
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
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // 0ms - 400ms: Seed emerges with spring bounce
    _seedFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.04, 0.22, curve: Curves.easeOut),
    );
    _seedScale = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.04, 0.28, curve: Curves.easeOutBack),
      ),
    );

    // 350ms - 800ms: Concentric soil ripples pulse outward
    _rippleProgress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.18, 0.50, curve: Curves.easeOutCubic),
    );

    // 600ms - 1300ms: Vibrant sprout leaves unfurl
    _leafGrowth = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.28, 0.62, curve: Curves.easeOutCubic),
    );

    // 1100ms - 1750ms: Serif wordmark reveal with golden glow
    _wordmarkReveal = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.48, 0.76, curve: Curves.easeOutCubic),
    );

    // 1600ms - 2200ms: Tagline fades upward with badge
    _taglineFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.66, 0.90, curve: Curves.easeOut),
    );

    _glowPulse = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeInOut),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted && !_readyDispatched) {
        _readyDispatched = true;
        widget.onReady();
      }
    });

    // Start immediately without waiting for async image precaching
    _controller.forward();

    // Background asset warming
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final name in [
        'farm',
        'honey',
        'market',
        'potatoes',
        'strawberries',
        'tomatoes',
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
      // Reduced motion fallback
      return Scaffold(
        backgroundColor: const Color(0xFF071F15),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SeedMark(size: 72),
              const SizedBox(height: 24),
              Text(
                'HarvestHub',
                style: Harvest.editorial(40, color: const Color(0xFFFFFBEB)),
              ),
              const SizedBox(height: 10),
              const Text(
                'Fresh from farms. Closer to you.',
                style: TextStyle(
                  color: Color(0xFFCDE3D5),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 36),
              HarvestButton(
                label: 'Get Started',
                color: const Color(0xFF16A34A),
                onPressed: _finishNow,
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.15),
            radius: 1.15,
            colors: [Color(0xFF164E35), Color(0xFF09281C), Color(0xFF04140D)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Skip button in top corner
              Positioned(
                top: 16,
                right: 20,
                child: TextButton.icon(
                  onPressed: _finishNow,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFFFFBEB)
                        .withValues(alpha: 0.8),
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                  label: const Text(
                    'Explore Now',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ),

              // Animated central stage
              Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Concentric glowing rings & sprout mark
                      SizedBox(
                        width: 170,
                        height: 150,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Outer ambient aura
                            if (_rippleProgress.value > 0) ...[
                              Opacity(
                                opacity: ((1.0 - _rippleProgress.value) * 0.7)
                                    .clamp(0.0, 1.0),
                                child: Container(
                                  width: 60 + (_rippleProgress.value * 90),
                                  height: 60 + (_rippleProgress.value * 90),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFFF59E0B)
                                          .withValues(alpha: 0.4),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF22C55E)
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
                                  width: 40 + (_rippleProgress.value * 125),
                                  height: 40 + (_rippleProgress.value * 125),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: const Color(0xFF34D399)
                                          .withValues(alpha: 0.3),
                                      width: 1.0,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            // Central growing sprout
                            Transform.scale(
                              scale: _seedScale.value,
                              child: Opacity(
                                opacity: _seedFade.value,
                                child: Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const RadialGradient(
                                      colors: [
                                        Color(0x3334D399),
                                        Colors.transparent,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFF59E0B)
                                            .withValues(
                                              alpha:
                                                  0.3 *
                                                  _glowPulse.value.clamp(
                                                    0.5,
                                                    1.0,
                                                  ),
                                            ),
                                        blurRadius: 32,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Center(
                                    child: CustomPaint(
                                      size: const Size(64, 64),
                                      painter: _SproutPainter(
                                        progress: _leafGrowth.value,
                                        color: const Color(0xFF34D399),
                                        accentColor: const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Elegant masked wordmark reveal
                      ClipRect(
                        child: Align(
                          alignment: Alignment.topCenter,
                          heightFactor: _wordmarkReveal.value,
                          child: Opacity(
                            opacity: _wordmarkReveal.value,
                            child: Column(
                              children: [
                                Text(
                                  'HarvestHub',
                                  style: Harvest.editorial(
                                    44,
                                    color: const Color(0xFFFFFBEB),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'HARVEST LIVING',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 3.2,
                                        color: const Color(0xFFF59E0B)
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 4,
                                      height: 4,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF59E0B),
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

                      // Tagline with subtle upward slide
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Transform.translate(
                          offset: Offset(0, 14 * (1.0 - _taglineFade.value)),
                          child: Column(
                            children: [
                              const Text(
                                'Fresh from farms. Closer to you.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.2,
                                  color: Color(0xFFCDE3D5),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: const Color(0xFFF59E0B)
                                        .withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  '✦ 100% CERTIFIED LOCAL & ORGANIC ✦',
                                  style: TextStyle(
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

              // Bottom animated indicator
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
                        Color(0xFF34D399),
                      ),
                      minHeight: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SproutPainter extends CustomPainter {
  _SproutPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });

  final double progress;
  final Color color;
  final Color accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..color = color;
    final accentPaint = Paint()..color = accentColor;

    // Golden Seed base
    final seedPath = Path()
      ..moveTo(24, 38)
      ..cubicTo(20, 38, 19, 32, 24, 27)
      ..cubicTo(29, 32, 28, 38, 24, 38);

    if (progress <= 0.1) {
      canvas.drawPath(seedPath, accentPaint);
      return;
    }

    // Growing left leaf (lush emerald)
    final leftLeaf = Path()
      ..moveTo(24, 38)
      ..cubicTo(
        24 - (17 * progress),
        38 - (1 * progress),
        24 - (20 * progress),
        38 - (17 * progress),
        24 - (17 * progress),
        38 - (26 * progress),
      )
      ..cubicTo(
        24 - (1 * progress),
        38 - (27 * progress),
        24 + (2 * progress),
        38 - (15 * progress),
        24,
        38,
      );
    canvas.drawPath(leftLeaf, paint);

    // Growing right leaf with honey warm tint highlight
    if (progress > 0.3) {
      final p2 = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
      final rightLeaf = Path()
        ..moveTo(26, 28)
        ..cubicTo(
          26 - (2 * p2),
          28 - (15 * p2),
          26 + (8 * p2),
          28 - (23 * p2),
          26 + (17 * p2),
          28 - (23 * p2),
        )
        ..cubicTo(
          26 + (19 * p2),
          28 - (9 * p2),
          26 + (13 * p2),
          28 + (1 * p2),
          26,
          28,
        );
      canvas.drawPath(rightLeaf, accentPaint);
    }

    // Delicate stem
    final stem = Path()
      ..moveTo(24, 44)
      ..quadraticBezierTo(25.5, 31, 24 + (7 * progress), 44 - (22 * progress));
    canvas.drawPath(
      stem,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SproutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor;
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onPreview,
    this.onReplaySplash,
  });

  final ValueChanged<UserRole> onPreview;
  final VoidCallback? onReplaySplash;

  void preview(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    builder: (sheet) => SheetBody(
      children: [
        Row(
          children: [
            const SeedMark(size: 28),
            const SizedBox(width: 10),
            Text('Explore by role', style: Harvest.editorial(26)),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Sample live workflows with realistic local produce data. All interactions stay in your local session.',
          style: TextStyle(fontSize: 13, color: Harvest.muted, height: 1.45),
        ),
        const SizedBox(height: 20),
        for (final role in UserRole.values)
          MenuRow(
            title: '${role.label} portal',
            subtitle: switch (role) {
              UserRole.customer => 'Browse seasonal harvests, AI nutrition guide, basket & checkout.',
              UserRole.farmer => 'Inventory controls, order status progressions, revenue & stock reports.',
              UserRole.admin => 'Platform metrics, farmer verification, customer directories & categories.',
            },
            icon: switch (role) {
              UserRole.customer => Icons.shopping_basket_outlined,
              UserRole.farmer => Icons.eco_outlined,
              UserRole.admin => Icons.admin_panel_settings_outlined,
            },
            onTap: () {
              Navigator.pop(sheet);
              onPreview(role);
            },
          ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Harvest.cream,
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
        children: [
          if (HarvestScope.of(context).error != null)
            InfoNote(HarvestScope.of(context).error!, error: true),
          // Top Brand Navigation Row
          Row(
            children: [
              const SeedMark(size: 32),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'HarvestHub',
                  style: Harvest.editorial(25, color: Harvest.forest),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Harvest.sage,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Harvest.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF16A34A),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      '48+ Farms',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Harvest.forest,
                      ),
                    ),
                  ],
                ),
              ),
              if (onReplaySplash != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  tooltip: 'Replay launch intro',
                  onPressed: onReplaySplash,
                  icon: const Icon(
                    Icons.motion_photos_on_outlined,
                    color: Harvest.forest,
                    size: 22,
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 28),

          // Editorial Eyebrow & Hero
          const Eyebrow('Harvest Living · Fresh Local Marketplace'),
          const SizedBox(height: 12),
          Text('Good food.\nGood roots.', style: Harvest.editorial(46)),
          const SizedBox(height: 12),
          const Text(
            'Meet independent local growers. Taste harvest-fresh produce. Make wholesome eating a daily ritual.',
            style: TextStyle(
              color: Harvest.muted,
              fontSize: 15,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),

          // Value Props Pill Bar
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BenefitPill(
                icon: Icons.flash_on_rounded,
                label: '<24h Fresh',
                color: Harvest.honey,
              ),
              _BenefitPill(
                icon: Icons.eco_rounded,
                label: '100% Organic',
                color: Harvest.freshLeaf,
              ),
              _BenefitPill(
                icon: Icons.star_rounded,
                label: '4.9 Rated',
                color: Harvest.tomato,
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Visual Feature Card
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                const Photo(
                  'tomatoes',
                  height: 200,
                  width: double.infinity,
                  radius: 24,
                  label: 'Fresh organic vine tomatoes',
                ),
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.15),
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                        stops: const [0.0, 0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.verified_rounded,
                          size: 14,
                          color: Color(0xFF16A34A),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Greenfield Organic Farm',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F3826),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 14,
                  left: 14,
                  right: 14,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Text(
                          'Vine-Ripened Heirloom Tomatoes',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Rs 180 / kg',
                        style: TextStyle(
                          color: Color(0xFFFDE68A),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'How will you use HarvestHub?',
            style: Harvest.editorial(23, color: Harvest.ink),
          ),
          const SizedBox(height: 14),

          // Customer Role Card
          _RoleCard(
            title: 'Shop fresh',
            subtitle: 'Seasonal produce, AI nutrition assistant, local basket.',
            icon: Icons.shopping_basket_rounded,
            iconBg: const Color(0xFFE8F5EE),
            iconColor: Harvest.forest,
            badge: 'Shopper',
            onTap: () => openPage(
              context,
              AuthScreen(role: UserRole.customer, onPreview: onPreview),
            ),
          ),
          const SizedBox(height: 12),

          // Farmer Role Card
          _RoleCard(
            title: 'Grow & sell',
            subtitle: 'Your farm stand, inventory management, customer orders.',
            icon: Icons.eco_rounded,
            iconBg: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            badge: 'Farmer',
            onTap: () => openPage(
              context,
              AuthScreen(role: UserRole.farmer, onPreview: onPreview),
            ),
          ),
          const SizedBox(height: 12),

          // Admin Access
          Center(
            child: TextButton.icon(
              onPressed: () => openPage(
                context,
                AuthScreen(role: UserRole.admin, onPreview: onPreview),
              ),
              icon: const Icon(
                Icons.shield_outlined,
                size: 16,
                color: Harvest.muted,
              ),
              label: const Text(
                'Administrator access',
                style: TextStyle(
                  color: Harvest.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Divider(height: 28),

          // Test-only preview gateway.
          if (!HarvestScope.of(context).live)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEDF6F0), Color(0xFFFAFCFA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Harvest.border),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.play_circle_fill_rounded,
                        size: 22,
                        color: Harvest.forest,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'Instant Interactive Role Preview',
                          style: Harvest.sans(
                            15,
                            weight: FontWeight.w800,
                            color: Harvest.forest,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Explore full customer, farmer and admin features seamlessly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Harvest.muted),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: HarvestButton(
                      label: 'Explore Roles Demo',
                      icon: Icons.visibility_outlined,
                      onPressed: () => preview(context),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    ),
  );
}

class _BenefitPill extends StatelessWidget {
  const _BenefitPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Harvest.border),
      boxShadow: const [
        BoxShadow(
          color: Color(0x060C2D1F),
          blurRadius: 8,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Harvest.ink,
          ),
        ),
      ],
    ),
  );
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.badge,
    required this.onTap,
  });

  final String title, subtitle;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Harvest.border, width: 1.2),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A0C2D1F),
          blurRadius: 16,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 28, color: iconColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Harvest.ink,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 7,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: iconColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Harvest.muted,
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Harvest.canvas,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  size: 16,
                  color: Harvest.forest,
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.onExit});
  final VoidCallback onExit;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int index = 0;
  final Map<int, Widget> pages = {};

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
        Icons.bar_chart_rounded,
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

    return Scaffold(
      backgroundColor: Harvest.cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Top Preview status strip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              color: Harvest.sage,
              child: Row(
                children: [
                  const SeedMark(size: 14, color: Harvest.forest),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'HARVEST LIVING · ${role.label.toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Harvest.forest,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: widget.onExit,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(40, 28),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (store.live) const DataStatusBar(),
            Expanded(
              child: IndexedStack(
                index: index,
                children: List.generate(
                  5,
                  (i) => pages[i] ?? const SizedBox.shrink(),
                ),
              ),
            ),
          ],
        ),
      ),
      // Floating White Pill Navigation Bar matching Reference Images 1 and 2
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 2, 16, 10),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Harvest.border.withValues(alpha: 0.6)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x140E4D34),
                  blurRadius: 20,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: List.generate(5, (i) {
                final isSelected = index == i;
                return Expanded(
                  child: Semantics(
                    selected: isSelected,
                    button: true,
                    label: labels[i],
                    child: InkWell(
                      onTap: () => select(i),
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: MediaQuery.disableAnimationsOf(context)
                                  ? Duration.zero
                                  : Harvest.motion,
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Harvest.sage
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                icons[i],
                                size: 22,
                                color: isSelected
                                    ? Harvest.forest
                                    : Harvest.muted,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              labels[i],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: isSelected
                                    ? Harvest.forest
                                    : Harvest.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
