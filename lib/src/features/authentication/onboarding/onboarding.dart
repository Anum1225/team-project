import 'package:flutter/material.dart';

import '../../common/shared/components.dart';
import '../../common/shared/theme.dart';

/// Awards-Grade Onboarding Experience matching HarvestHub 2026 Reference UI
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, required this.onFinish});

  final VoidCallback onFinish;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _controller = PageController();
  int _currentPage = 0;

  late final AnimationController _slideEntrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  late final List<Animation<double>> _stagger = [
    CurvedAnimation(
      parent: _slideEntrance,
      curve: const Interval(0.0, 0.50, curve: Curves.easeOutCubic),
    ),
    CurvedAnimation(
      parent: _slideEntrance,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    ),
    CurvedAnimation(
      parent: _slideEntrance,
      curve: const Interval(0.30, 0.80, curve: Curves.easeOutCubic),
    ),
    CurvedAnimation(
      parent: _slideEntrance,
      curve: const Interval(0.45, 1.0, curve: Curves.easeOutCubic),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _slideEntrance.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _slideEntrance.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 3) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      widget.onFinish();
    }
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
    _slideEntrance.reset();
    _slideEntrance.forward();
  }

  Widget _fadeSlide(int slot, Widget child) => AnimatedBuilder(
    animation: _stagger[slot.clamp(0, 3)],
    builder: (context, _) => Opacity(
      opacity: _stagger[slot.clamp(0, 3)].value,
      child: Transform.translate(
        offset: Offset(0, 24 * (1 - _stagger[slot.clamp(0, 3)].value)),
        child: child,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar: Skip Button only (theme toggle removed per request)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: widget.onFinish,
                    style: TextButton.styleFrom(
                      foregroundColor: colors.muted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.muted,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: colors.muted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Page View with smooth transitions
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: _onPageChanged,
                children: [
                  _buildSlide1(context, colors, isDark),
                  _buildSlide2(context, colors, isDark),
                  _buildSlide3(context, colors, isDark),
                  _buildSlide4(context, colors, isDark),
                ],
              ),
            ),

            // Bottom Navigation Row: Animated Indicator + Action Button
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Animated dot indicators
                  Row(
                    children: List.generate(4, (index) {
                      final active = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 350),
                        curve: Curves.easeOutCubic,
                        margin: const EdgeInsets.only(right: 8),
                        height: 8,
                        width: active ? 28 : 8,
                        decoration: BoxDecoration(
                          color: active ? colors.green : colors.border,
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: active
                              ? [
                                  BoxShadow(
                                    color: colors.green.withValues(alpha: 0.35),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),

                  AnimatedSwitcher(
                    duration: MediaQuery.disableAnimationsOf(context)
                        ? Duration.zero
                        : const Duration(milliseconds: 380),
                    switchInCurve: Curves.easeOutBack,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: ScaleTransition(scale: animation, child: child),
                    ),
                    child: _currentPage == 3
                        ? ElevatedButton(
                            key: const ValueKey('start'),
                            onPressed: widget.onFinish,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E5631),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF1E5631)
                                  .withValues(alpha: 0.4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Get Started',
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(Icons.arrow_forward_rounded, size: 18),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            key: const ValueKey('next'),
                            onPressed: _nextPage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1E5631),
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: const Color(0xFF1E5631)
                                  .withValues(alpha: 0.4),
                              shape: const CircleBorder(),
                              padding: const EdgeInsets.all(18),
                            ),
                            child: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 22,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Slide 1: Farm-to-Table Community
  Widget _buildSlide1(
    BuildContext context,
    HarvestPalette colors,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: _fadeSlide(
              0,
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Stack(
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
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.5),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SeedMark(size: 22),
                            const SizedBox(width: 8),
                            RichText(
                              text: const TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'Harvest',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFF1E5631),
                                    ),
                                  ),
                                  TextSpan(
                                    text: 'Hub',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16,
                                      color: Color(0xFFE8A93B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 20,
                      left: 20,
                      right: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.65),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              color: Color(0xFF86EFAC),
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Fresh from Farms · Good for You',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontFamily: 'Manrope',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlide(
                  1,
                  Text(
                    'Fresh Food\nStronger Communities',
                    style: Harvest.editorial(
                      30,
                      color: colors.ink,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fadeSlide(
                  2,
                  Text(
                    'Connect with local farmers, get fresh farm products, and support sustainable living.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  3,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillTag(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Fresh & Healthy',
                        color: colors.green,
                      ),
                      _PillTag(
                        icon: Icons.people_outline_rounded,
                        label: 'Support Local Farmers',
                        color: const Color(0xFFE8A93B),
                      ),
                      _PillTag(
                        icon: Icons.nature_people_outlined,
                        label: 'Sustainable Living',
                        color: const Color(0xFF5C8A3A),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 2: Fresh Food at Your Fingertips
  Widget _buildSlide2(
    BuildContext context,
    HarvestPalette colors,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16251C)
                    : const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // App Mockup Header
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: Color(0xFF3D7A44),
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Karachi, Pakistan',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: colors.ink,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5EE),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Open Stalls',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E5631),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mini Product Grid Showcase
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _MiniProductShowcase(
                          image: 'assets/images/tomatoes.jpg',
                          title: 'Fresh Tomatoes',
                          price: 'Rs. 120 / kg',
                          color: colors.surface,
                        ),
                        _MiniProductShowcase(
                          image: 'assets/images/carrots.jpg',
                          title: 'Organic Carrots',
                          price: 'Rs. 100 / kg',
                          color: colors.surface,
                        ),
                        _MiniProductShowcase(
                          image: 'assets/images/apples.jpg',
                          title: 'Red Apples',
                          price: 'Rs. 250 / kg',
                          color: colors.surface,
                        ),
                        _MiniProductShowcase(
                          image: 'assets/images/spinach.jpg',
                          title: 'Fresh Lettuce',
                          price: 'Rs. 80 / kg',
                          color: colors.surface,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlide(
                  1,
                  Text(
                    'Fresh Food\nat Your Fingertips',
                    style: Harvest.editorial(
                      30,
                      color: colors.ink,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fadeSlide(
                  2,
                  Text(
                    'Browse fresh fruits, vegetables, dairy and artisan pantry items directly from local growers.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  3,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillTag(
                        icon: Icons.bolt_rounded,
                        label: 'Discover Fresh Produce',
                        color: const Color(0xFFE8A93B),
                      ),
                      _PillTag(
                        icon: Icons.verified_rounded,
                        label: 'Direct Pricing',
                        color: colors.green,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 3: Support Local Farmers
  Widget _buildSlide3(
    BuildContext context,
    HarvestPalette colors,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/farmer_holding_crate.jpg',
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        _BadgeTag(label: '🌾 Better Income for Farmers'),
                        const SizedBox(height: 6),
                        _BadgeTag(label: '👥 Stronger Communities'),
                        const SizedBox(height: 6),
                        _BadgeTag(label: '🌍 A Greener Tomorrow'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlide(
                  1,
                  Text(
                    'Support\nLocal Farmers',
                    style: Harvest.editorial(
                      30,
                      color: colors.ink,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fadeSlide(
                  2,
                  Text(
                    'Buy directly from independent growers and keep agricultural economics healthy and transparent.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  3,
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _PillTag(
                        icon: Icons.eco_rounded,
                        label: 'Zero Middlemen',
                        color: colors.green,
                      ),
                      _PillTag(
                        icon: Icons.handshake_rounded,
                        label: 'Fair Trade Value',
                        color: const Color(0xFFE8A93B),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Slide 4: Your AI Farm Assistant
  Widget _buildSlide4(
    BuildContext context,
    HarvestPalette colors,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Expanded(
            flex: 6,
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF16251C)
                    : const Color(0xFFE8F5EE),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: colors.border),
              ),
              padding: const EdgeInsets.all(16),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/ai_farm_robot.jpg',
                        height: 220,
                        width: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _SpeechBubble(text: '🍎 Nutrition Tips'),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _SpeechBubble(text: '💡 Storage Advice'),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 10,
                    child: _SpeechBubble(text: '🥗 Healthy Recipes'),
                  ),
                  Positioned(
                    bottom: 20,
                    right: 10,
                    child: _SpeechBubble(text: '🚜 Farming Info'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _fadeSlide(
                  1,
                  Text(
                    'Your AI\nFarm Assistant',
                    style: Harvest.editorial(
                      30,
                      color: colors.ink,
                      height: 1.15,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _fadeSlide(
                  2,
                  Text(
                    'Get instant answers about nutritional values, freshness storage tricks, seasonal recipes, and produce handling.',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      color: colors.muted,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _fadeSlide(
                  3,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.smart_toy_rounded,
                          size: 16,
                          color: colors.green,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Ask anything about healthy living & recipes!',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.ink,
                          ),
                        ),
                      ],
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

class _MiniProductShowcase extends StatelessWidget {
  const _MiniProductShowcase({
    required this.image,
    required this.title,
    required this.price,
    required this.color,
  });

  final String image;
  final String title;
  final String price;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            price,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E5631),
            ),
          ),
        ],
      ),
    );
  }
}

class _PillTag extends StatelessWidget {
  const _PillTag({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeTag extends StatelessWidget {
  const _BadgeTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8),
        ],
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF16251C),
        ),
      ),
    );
  }
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
        ],
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E5631),
        ),
      ),
    );
  }
}
