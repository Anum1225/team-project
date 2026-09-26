import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'assistant.dart';
import 'auth.dart';
import 'components.dart';
import 'customer.dart';
import 'models.dart';
import 'onboarding.dart';
import 'operations.dart';
import 'orders.dart';
import 'store.dart';
import 'firebase_store.dart';
import 'profile.dart';
import 'theme.dart';
import 'theme_reveal.dart';

class HarvestHubApp extends StatefulWidget {
  const HarvestHubApp({
    super.key,
    this.initialRole,
    this.store,
    this.skipStartup = false,
    this.initialOnboardingSeen = false,
  });

  final UserRole? initialRole;
  final HarvestStore? store;
  final bool skipStartup;
  final bool initialOnboardingSeen;

  @override
  State<HarvestHubApp> createState() => _HarvestHubAppState();
}

class _HarvestHubAppState extends State<HarvestHubApp> {
  late final HarvestStore store = widget.store ?? FirebaseStore();
  late bool preview = widget.initialRole != null;
  late bool ready = widget.skipStartup;
  late bool seenOnboarding = widget.skipStartup || widget.initialOnboardingSeen;

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
    if (widget.store == null) store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestScope(
    store: store,
    child: ThemeReveal(
      builder: (mode, wrap) => MaterialApp(
        key: ValueKey(
          store.live ? '${store.authenticated}:${store.role}' : 'preview',
        ),
        title: 'HarvestHub',
        debugShowCheckedModeBanner: false,
        theme: Harvest.theme,
        darkTheme: Harvest.darkTheme,
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
        home: !ready
            ? StartupScreen(onReady: () => setState(() => ready = true))
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
            : const AuthScreen(role: UserRole.customer),
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
      duration: const Duration(milliseconds: 2600),
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
                Positioned(
                  top: 16,
                  right: 20,
                  child: TextButton.icon(
                    onPressed: _finishNow,
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(
                        0xFFF2EFE9,
                      ).withValues(alpha: 0.90),
                      backgroundColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.arrow_forward_rounded, size: 14),
                    label: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Manrope',
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
                                        color: const Color(
                                          0xFFE8A93B,
                                        ).withValues(alpha: 0.45),
                                        width: 1.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF5C8A3A,
                                          ).withValues(alpha: 0.25),
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
                                        color: const Color(
                                          0xFF8FC494,
                                        ).withValues(alpha: 0.35),
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
                                        painter: _SproutPainter(
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
                                          color: const Color(
                                            0xFFE8A93B,
                                          ).withValues(alpha: 0.95),
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
                                    color: const Color(
                                      0xFFE8A93B,
                                    ).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: const Color(
                                        0xFFE8A93B,
                                      ).withValues(alpha: 0.40),
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

    final plantPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final goldPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    final strokeGold = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // 1. Soil mound & seed at base (0.0 to 0.22)
    final seedY = 28.0 + (10.0 * progress.clamp(0.0, 0.2) / 0.2);
    final seedPath = Path()
      ..moveTo(24, seedY)
      ..cubicTo(20, seedY, 19, seedY - 6, 24, seedY - 11)
      ..cubicTo(29, seedY - 6, 28, seedY, 24, seedY);

    if (progress <= 0.16) {
      canvas.drawPath(seedPath, goldPaint);
      return;
    }

    // 2. Rising central stem with natural organic flex (0.16 to 0.65)
    final stemP = ((progress - 0.16) / 0.50).clamp(0.0, 1.0);
    final stem = Path()
      ..moveTo(24, 42)
      ..quadraticBezierTo(
        24 - (2 * (1.0 - stemP)),
        32,
        24 + (3 * stemP),
        42 - (26 * stemP),
      );
    canvas.drawPath(
      stem,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round,
    );

    // 3. Left botanical leaf unfurls (0.26 to 0.75)
    if (progress > 0.26) {
      final lp = ((progress - 0.26) / 0.46).clamp(0.0, 1.0);
      final leftLeaf = Path()
        ..moveTo(24, 36)
        ..cubicTo(
          24 - (19 * lp),
          36 - (2 * lp),
          24 - (24 * lp),
          36 - (18 * lp),
          24 - (18 * lp),
          36 - (28 * lp),
        )
        ..cubicTo(
          24 - (3 * lp),
          36 - (28 * lp),
          24 + (2 * lp),
          36 - (16 * lp),
          24,
          36,
        );
      canvas.drawPath(leftLeaf, plantPaint);

      // Delicate leaf center vein
      final leftVein = Path()
        ..moveTo(24, 36)
        ..quadraticBezierTo(
          24 - (10 * lp),
          36 - (14 * lp),
          24 - (18 * lp),
          36 - (28 * lp),
        );
      canvas.drawPath(
        leftVein,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );

      // Morning dewdrop glint
      if (lp > 0.6) {
        canvas.drawCircle(
          Offset(24 - (18 * lp), 36 - (28 * lp)),
          1.8,
          goldPaint,
        );
      }
    }

    // 4. Right symmetrical organic leaf (0.34 to 0.82)
    if (progress > 0.34) {
      final rp = ((progress - 0.34) / 0.46).clamp(0.0, 1.0);
      final rightLeaf = Path()
        ..moveTo(24, 34)
        ..cubicTo(
          24 + (19 * rp),
          34 - (2 * rp),
          24 + (24 * rp),
          34 - (18 * rp),
          24 + (18 * rp),
          34 - (28 * rp),
        )
        ..cubicTo(
          24 + (3 * rp),
          34 - (28 * rp),
          24 - (2 * rp),
          34 - (16 * rp),
          24,
          34,
        );
      canvas.drawPath(rightLeaf, plantPaint);

      // Right leaf center vein
      final rightVein = Path()
        ..moveTo(24, 34)
        ..quadraticBezierTo(
          24 + (10 * rp),
          34 - (14 * rp),
          24 + (18 * rp),
          34 - (28 * rp),
        );
      canvas.drawPath(
        rightVein,
        Paint()
          ..color = Colors.white.withValues(alpha: 0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0,
      );
    }

    // 5. Crown harvest ear & golden grains at apex (0.48 to 1.0)
    if (progress > 0.48) {
      final wp = ((progress - 0.48) / 0.48).clamp(0.0, 1.0);
      // Wheat apex stem
      final wheatStem = Path()
        ..moveTo(24, 26)
        ..quadraticBezierTo(25, 18, 24 + (4 * wp), 8 * wp + (1.0 - wp) * 26);
      canvas.drawPath(
        wheatStem,
        Paint()
          ..color = accentColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );

      // 6 Golden grain husks fanning upwards
      for (var i = 0; i < 5; i++) {
        if (wp > 0.15 + (i * 0.16)) {
          final grainP = ((wp - (0.15 + (i * 0.16))) / 0.20).clamp(0.0, 1.0);
          final gy = 22.0 - (i * 3.8);
          final gx = 24.5 + (i * 0.8);

          // Left grain husk
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(gx - (4.0 * grainP), gy),
              width: 5.5 * grainP,
              height: 3.2 * grainP,
            ),
            goldPaint,
          );
          // Right grain husk
          canvas.drawOval(
            Rect.fromCenter(
              center: Offset(gx + (4.0 * grainP), gy - 1.2),
              width: 5.5 * grainP,
              height: 3.2 * grainP,
            ),
            goldPaint,
          );
        }
      }
    }

    // 6. Base fertile earth cradle (0.62 to 1.0)
    if (progress > 0.62) {
      final bp = ((progress - 0.62) / 0.38).clamp(0.0, 1.0);
      final earthArc = Path()
        ..moveTo(12, 40)
        ..quadraticBezierTo(24, 46, 36, 40);
      canvas.drawPath(earthArc, strokeGold..strokeWidth = 2.0 * bp);
      if (bp > 0.4) {
        canvas.drawCircle(const Offset(24, 42.5), 1.5 * bp, goldPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_SproutPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.accentColor != accentColor;
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

    return Scaffold(
      backgroundColor: Harvest.colors(context).cream,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            if (store.live &&
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
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      AnimatedScale(
                                        scale: selected ? 1.08 : 1,
                                        duration: noMotion
                                            ? Duration.zero
                                            : const Duration(milliseconds: 220),
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
                                          horizontal: 2,
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
                                              letterSpacing: 0.05,
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
    );
  }
}
