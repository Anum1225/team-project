import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../common/shared/theme.dart';

/// Vector adaptation of the supplied Ola mascot in HarvestHub's brand colors.
class AssistantRobot extends StatefulWidget {
  const AssistantRobot({super.key, required this.onTap, this.onDismiss});
  final VoidCallback onTap;
  final VoidCallback? onDismiss;

  @override
  State<AssistantRobot> createState() => _AssistantRobotState();
}

class _AssistantRobotState extends State<AssistantRobot>
    with SingleTickerProviderStateMixin {
  Timer? _pause;
  bool _animate = false;
  late final AnimationController _motion =
      AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 4800),
      )..addStatusListener((status) {
        if (status == AnimationStatus.completed && _animate) {
          // A short rest keeps the motion gentle and gives the mascot a natural
          // pause. Painting is isolated from the rest of the dashboard.
          _pause = Timer(const Duration(milliseconds: 700), () {
            if (mounted && _animate) _motion.forward(from: 0);
          });
        }
      });

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animate =
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate == _animate) return;
    _animate = animate;
    _pause?.cancel();
    if (animate) {
      _motion.forward(from: 0);
    } else {
      _motion.stop();
      _motion.value = 0;
    }
  }

  @override
  void dispose() {
    _pause?.cancel();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: widget.onDismiss == null ? 64 : 92,
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            right: 0,
            width: 64,
            height: 64,
            child: Semantics(
              button: true,
              label: 'Ask Ola. Open assistant',
              child: Tooltip(
                message: 'Ask Ola',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: widget.onTap,
                    borderRadius: BorderRadius.circular(28),
                    child: Center(child: OlaMascot(size: 60, motion: _motion)),
                  ),
                ),
              ),
            ),
          ),
          if (widget.onDismiss != null)
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                constraints: const BoxConstraints.tightFor(
                  width: 40,
                  height: 40,
                ),
                tooltip: 'Hide Ola assistant',
                onPressed: widget.onDismiss,
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  minimumSize: const Size(40, 40),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: const EdgeInsets.all(6),
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

/// Decorative artwork for the floating control and the static chat header.
class OlaMascot extends StatelessWidget {
  const OlaMascot({
    super.key,
    this.size = 36,
    this.motion = const AlwaysStoppedAnimation<double>(0),
    this.showShadow = true,
  });

  final double size;
  final Animation<double> motion;
  final bool showShadow;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: RepaintBoundary(
      child: CustomPaint(
        size: Size.square(size),
        painter: _OlaPainter(motion, Harvest.colors(context), showShadow),
      ),
    ),
  );
}

class _OlaPainter extends CustomPainter {
  _OlaPainter(this.motion, this.palette, this.showShadow)
    : super(repaint: motion);
  final Animation<double> motion;
  final HarvestPalette palette;
  final bool showShadow;

  double _blink(double phase, double start) {
    const duration = .052;
    final t = (phase - start) / duration;
    if (t <= 0 || t >= 1) return 0;
    return math.pow(math.sin(t * math.pi), 2).toDouble();
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 280, size.height / 280);
    final phase = motion.value;
    final bob = (1 - math.cos(phase * math.pi * 4)) / 2;
    final blink = math.max(_blink(phase, .34), _blink(phase, .86));
    if (showShadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: const Offset(140, 267),
          width: 176 - bob * 22,
          height: 10 - bob * 2,
        ),
        Paint()
          ..color = Colors.black.withValues(alpha: .10 - bob * .025)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 9),
      );
    }
    canvas.translate(140, 135 - bob * 8);
    canvas.rotate(math.sin(phase * math.pi * 2) * .012);
    canvas.translate(-140, -135);
    final body = Path()
      ..moveTo(140, 8)
      ..cubicTo(65, 8, 8, 72, 5, 143)
      ..cubicTo(2, 190, 15, 229, 36, 249)
      ..cubicTo(54, 267, 73, 259, 88, 240)
      ..lineTo(118, 228)
      ..cubicTo(131, 214, 145, 214, 158, 228)
      ..lineTo(187, 240)
      ..cubicTo(204, 260, 224, 268, 243, 247)
      ..cubicTo(264, 225, 276, 185, 275, 144)
      ..cubicTo(273, 70, 215, 8, 140, 8)
      ..close();
    canvas.drawPath(
      body,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.lerp(palette.freshLeaf, HarvestPalette.light.cream, .24)!,
            palette.green,
            Color.lerp(palette.green, const Color(0xFF163D26), .5)!,
          ],
          stops: [0, .50, 1],
        ).createShader(const Rect.fromLTWH(0, 8, 280, 252)),
    );
    canvas.drawOval(
      const Rect.fromLTWH(60, 35, 160, 142),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFF6F5E9)],
        ).createShader(const Rect.fromLTWH(60, 35, 160, 142)),
    );
    for (final x in [97.0, 153.0]) {
      final eye = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF79A653), Color(0xFF3D7A44)],
        ).createShader(Rect.fromLTWH(x, 84, 30, 45));
      canvas.save();
      canvas.translate(x + 13, 110);
      canvas.scale(1 + blink * .06, math.max(.04, 1 - blink));
      canvas.translate(-x - 13, -110);
      final bean = Path()
        ..moveTo(x + 18, 84)
        ..cubicTo(x - 3, 89, x - 6, 111, x + 2, 121)
        ..cubicTo(x + 10, 133, x + 30, 127, x + 29, 111)
        ..lineTo(x + 27, 98)
        ..cubicTo(x + 17, 105, x + 11, 94, x + 18, 84)
        ..close();
      canvas.drawPath(bean, eye);
      canvas.drawOval(
        Rect.fromLTWH(x + 3, 94, 6, 9),
        Paint()..color = Colors.white.withValues(alpha: .85),
      );
      canvas.drawCircle(
        Offset(x + 18, 119),
        2,
        Paint()..color = Colors.white.withValues(alpha: .42),
      );
      canvas.restore();
      if (blink > .82) {
        canvas.drawPath(
          Path()
            ..moveTo(x, 110)
            ..quadraticBezierTo(x + 13, 116, x + 27, 109),
          Paint()
            ..color = const Color(0xFF3D7A44)
                .withValues(alpha: (blink - .82) / .18)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _OlaPainter oldDelegate) =>
      oldDelegate.motion != motion ||
      oldDelegate.palette != palette ||
      oldDelegate.showShadow != showShadow;
}
