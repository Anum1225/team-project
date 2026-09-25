import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/customer_theme.dart';

class HarvestArt extends StatelessWidget {
  const HarvestArt({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Illustration of a sunlit local farm with rolling fields',
    image: true,
    child: const CustomPaint(painter: _FarmPainter(), child: SizedBox.expand()),
  );
}

class _FarmPainter extends CustomPainter {
  const _FarmPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFE8EDCD),
    );
    canvas.drawCircle(
      Offset(w * .72, h * .22),
      w * .16,
      Paint()..color = const Color(0xFFEABB63),
    );
    final colors = [
      const Color(0xFFA9BC87),
      const Color(0xFF718E59),
      const Color(0xFF426645),
      const Color(0xFF2B523D),
    ];
    for (var i = 0; i < 4; i++) {
      final y = h * (.4 + i * .13);
      final path = Path()
        ..moveTo(0, y)
        ..cubicTo(w * .32, y - h * .18, w * .65, y + h * .15, w, y - h * .05)
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
      canvas.drawPath(path, Paint()..color = colors[i]);
    }
    final furrow = Paint()
      ..color = const Color(0xFF8EAA69)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 7; i++) {
      final path = Path()
        ..moveTo(w * (.1 + i * .13), h)
        ..quadraticBezierTo(w * (.2 + i * .06), h * .79, w * .78, h * .68);
      canvas.drawPath(path, furrow);
    }
    final house = Rect.fromLTWH(w * .21, h * .36, w * .18, h * .14);
    canvas.drawRect(house, Paint()..color = const Color(0xFFF6E9C6));
    canvas.drawPath(
      Path()
        ..moveTo(w * .18, h * .37)
        ..lineTo(w * .3, h * .26)
        ..lineTo(w * .42, h * .37)
        ..close(),
      Paint()..color = const Color(0xFFAD664D),
    );
    canvas.drawRect(
      Rect.fromLTWH(w * .28, h * .42, w * .045, h * .08),
      Paint()..color = green,
    );
    for (final x in [.12, .47, .55, .9]) {
      final y = h * (.45 + (x > .6 ? .08 : 0));
      canvas.drawLine(
        Offset(w * x, y),
        Offset(w * x, y - h * .17),
        Paint()
          ..color = green
          ..strokeWidth = 5,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * x, y - h * .17),
          width: w * .11,
          height: h * .22,
        ),
        Paint()..color = const Color(0xFF587748),
      );
    }
    final bird = Paint()
      ..color = green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var i = 0; i < 3; i++) {
      final x = w * (.17 + i * .07), y = h * (.18 + math.sin(i) * .025);
      canvas.drawPath(
        Path()
          ..moveTo(x - 8, y + 3)
          ..quadraticBezierTo(x - 3, y - 3, x, y + 2)
          ..quadraticBezierTo(x + 4, y - 3, x + 9, y + 3),
        bird,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
