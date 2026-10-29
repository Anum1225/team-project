import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Captures the previous frame so theme changes bloom with an
/// awards-level chromatic shockwave and fluid radial reveal, and provides
/// a floating quick-action button to replay the startup splash experience.
class ThemeReveal extends StatefulWidget {
  const ThemeReveal({super.key, required this.builder, this.onReplaySplash});

  final Widget Function(ThemeMode mode, Widget Function(Widget) wrap) builder;
  final VoidCallback? onReplaySplash;

  static void toggle(BuildContext context) {
    context.findAncestorStateOfType<_ThemeRevealState>()?.toggle(context);
  }

  @override
  State<ThemeReveal> createState() => _ThemeRevealState();
}

class _ThemeRevealState extends State<ThemeReveal>
    with SingleTickerProviderStateMixin {
  final boundary = GlobalKey();
  late final animation = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  ThemeMode mode = ThemeMode.system;
  ui.Image? previous;
  Offset origin = Offset.zero;
  bool switching = false;
  bool nextIsDark = false;

  Future<void> toggle(BuildContext context) async {
    if (switching) return;
    switching = true;
    final currentDark = Theme.of(context).brightness == Brightness.dark;
    nextIsDark = !currentDark;
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        final box =
            boundary.currentContext!.findRenderObject()
                as RenderRepaintBoundary;
        // The theme control lives in the page header. Reveal the new palette
        // downwards from that edge instead of from a floating mid-page button.
        origin = Offset(box.size.width - 36, 42);
        if (!box.debugNeedsPaint) previous = await box.toImage(pixelRatio: 1.5);
      }
      if (!mounted) return;
      animation.value = 0;
      setState(() => mode = currentDark ? ThemeMode.light : ThemeMode.dark);
      await animation.forward();
    } finally {
      if (mounted) {
        setState(() {
          previous?.dispose();
          previous = null;
        });
      }
      switching = false;
    }
  }

  @override
  void dispose() {
    animation.dispose();
    previous?.dispose();
    super.dispose();
  }

  Widget wrap(Widget child) => Builder(
    builder: (context) {
      return Stack(
        children: [
          RepaintBoundary(key: boundary, child: child),
          if (previous != null) ...[
            Positioned.fill(
              child: IgnorePointer(
                child: AnimatedBuilder(
                  animation: animation,
                  builder: (context, _) {
                    final progress = Curves.easeInOutCubic.transform(
                      animation.value,
                    );
                    return Stack(
                      children: [
                        ClipPath(
                          clipper: _BloomClip(origin, progress),
                          child: RawImage(image: previous, fit: BoxFit.fill),
                        ),
                        // Chromatic shockwave ring along the expanding bloom perimeter
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _ShockwavePainter(
                              origin: origin,
                              progress: progress,
                              isDarkTarget: nextIsDark,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      );
    },
  );

  @override
  Widget build(BuildContext context) => widget.builder(mode, wrap);
}

/// Expanding circular bloom mask cutting a hole through the previous frame.
class _BloomClip extends CustomClipper<Path> {
  _BloomClip(this.origin, this.progress);
  final Offset origin;
  final double progress;

  @override
  Path getClip(Size size) {
    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - origin).distance).reduce(math.max);

    return Path()
      ..fillType = PathFillType.evenOdd
      ..addRect(Offset.zero & size)
      ..addOval(
        Rect.fromCircle(center: origin, radius: maxRadius * progress + 0.5),
      );
  }

  @override
  bool shouldReclip(_BloomClip oldClipper) => oldClipper.progress != progress;
}

/// Awards-level luminous shockwave ripple along the expanding perimeter.
class _ShockwavePainter extends CustomPainter {
  _ShockwavePainter({
    required this.origin,
    required this.progress,
    required this.isDarkTarget,
  });

  final Offset origin;
  final double progress;
  final bool isDarkTarget;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.01 || progress >= 0.99) return;

    final maxRadius = [
      Offset.zero,
      Offset(size.width, 0),
      Offset(0, size.height),
      Offset(size.width, size.height),
    ].map((p) => (p - origin).distance).reduce(math.max);

    final currentRadius = maxRadius * progress;
    final fadeOut = (1.0 - progress).clamp(0.0, 1.0);

    // Dynamic flare color: glowing emerald-mint when entering dark mode,
    // luminous solar amber-gold when entering light mode.
    final primaryFlare = isDarkTarget
        ? const Color(0xFF8FC494)
        : const Color(0xFFE8A93B);
    final secondaryFlare = isDarkTarget
        ? const Color(0xFF5C8A3A)
        : const Color(0xFFFDE68A);

    // 1. Soft atmospheric outer aura
    final auraPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 32.0 * fadeOut
      ..color = primaryFlare.withValues(alpha: 0.35 * fadeOut)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(origin, currentRadius, auraPaint);

    // 2. High-intensity sharp shockwave core
    final corePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0 * fadeOut
      ..color = Colors.white.withValues(alpha: 0.90 * fadeOut);
    canvas.drawCircle(origin, currentRadius, corePaint);

    // 3. Trailing color ripple wave
    if (progress > 0.06) {
      final trailingRadius = currentRadius * 0.92;
      final trailPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * fadeOut
        ..color = secondaryFlare.withValues(alpha: 0.50 * fadeOut);
      canvas.drawCircle(origin, trailingRadius, trailPaint);
    }

    // 4. Inner glow wash
    if (progress > 0.04 && progress < 0.7) {
      final innerGlow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 50.0 * fadeOut
        ..color = primaryFlare.withValues(alpha: 0.10 * fadeOut)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
      canvas.drawCircle(origin, currentRadius * 0.85, innerGlow);
    }
  }

  @override
  bool shouldRepaint(_ShockwavePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.origin != origin ||
      oldDelegate.isDarkTarget != isDarkTarget;
}
