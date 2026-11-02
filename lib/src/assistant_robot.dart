import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Original vector artwork: no stock avatar or product data.
class AssistantRobot extends StatefulWidget {
  const AssistantRobot({super.key, required this.onTap});
  final VoidCallback onTap;
  @override
  State<AssistantRobot> createState() => _AssistantRobotState();
}

class _AssistantRobotState extends State<AssistantRobot>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3600),
  )..forward();
  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Semantics(
      button: true,
      label: 'Ola, got your question? Open AI chat',
      child: Tooltip(
        message: 'Ola, got your question?',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              width: 108,
              height: 124,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x553D9156)),
                    ),
                    child: const Text(
                      'Ola, got your\nquestion?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (_, _) => CustomPaint(
                        size: const Size(86, 76),
                        painter: _RobotPainter(reduced ? 0.25 : _motion.value),
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
  }
}

class _RobotPainter extends CustomPainter {
  const _RobotPainter(this.t);
  final double t;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 86, size.height / 76);
    canvas.translate(0, math.sin(t * math.pi * 2) * 2);
    final p = Paint()..isAntiAlias = true;
    canvas.drawOval(
      const Rect.fromLTWH(18, 68, 50, 6),
      p..color = const Color(0x22093720),
    );
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(23, 43, 40, 27),
      const Radius.circular(15),
    );
    canvas.drawRRect(
      body,
      p
        ..shader = const LinearGradient(
          colors: [Color(0xFFF8FFF7), Color(0xFFB9D5BC)],
        ).createShader(body.outerRect),
    );
    p.shader = null;
    canvas.drawOval(
      const Rect.fromLTWH(6, 25, 12, 21),
      p..color = const Color(0xFF54AD68),
    );
    canvas.drawOval(const Rect.fromLTWH(68, 25, 12, 21), p);
    final head = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 10, 62, 43),
      const Radius.circular(21),
    );
    canvas.drawRRect(
      head,
      p
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.white, Color(0xFFBADBC3)],
        ).createShader(head.outerRect),
    );
    p.shader = null;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(19, 19, 48, 27),
        const Radius.circular(13),
      ),
      p..color = const Color(0xFF103D2B),
    );
    final blink = t > .87 && t < .93;
    for (final x in [33.0, 53.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, 32),
          width: 10,
          height: blink ? 2 : 13,
        ),
        p..color = const Color(0xFF91F9B3),
      );
      if (!blink) {
        canvas.drawCircle(Offset(x + 1, 30), 2, p..color = Colors.white);
      }
    }
    canvas.drawLine(
      const Offset(43, 11),
      const Offset(43, 5),
      p
        ..color = const Color(0xFF398A4C)
        ..strokeWidth = 3,
    );
    canvas.drawOval(
      const Rect.fromLTWH(43, 0, 12, 7),
      p..color = const Color(0xFF54AD68),
    );
    canvas.drawOval(
      const Rect.fromLTWH(34, 1, 10, 6),
      p..color = const Color(0xFF257144),
    );
    canvas.drawOval(
      const Rect.fromLTWH(36, 52, 7, 11),
      p..color = const Color(0xFF378B50),
    );
    canvas.drawOval(const Rect.fromLTWH(44, 50, 7, 12), p);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_RobotPainter oldDelegate) => oldDelegate.t != t;
}
