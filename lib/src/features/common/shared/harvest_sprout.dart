import 'package:flutter/material.dart';

/// Native vector counterpart of assets/images/harvest_sprout.svg.
class HarvestSproutPainter extends CustomPainter {
  const HarvestSproutPainter({
    required this.progress,
    required this.color,
    required this.accentColor,
  });
  final double progress;
  final Color color, accentColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 96, size.height / 96);
    final p = progress.clamp(0.0, 1.0);
    final stem = ((p - .1) / .55).clamp(0.0, 1.0);
    final leaf = Curves.easeOutCubic.transform(
      ((p - .24) / .6).clamp(0.0, 1.0),
    );
    final wheat = ((p - .52) / .48).clamp(0.0, 1.0);
    final gold = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(27, 81)
        ..quadraticBezierTo(48, 90, 69, 81),
      gold..color = accentColor.withValues(alpha: p),
    );
    canvas.drawPath(
      Path()
        ..moveTo(48, 82)
        ..lineTo(48, 82 - 47 * stem),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.8
        ..strokeCap = StrokeCap.round,
    );

    if (leaf > 0) {
      for (final side in [-1.0, 1.0]) {
        canvas.save();
        canvas.translate(48, 68);
        canvas.scale(side * leaf, leaf);
        canvas.translate(-48, -68);
        final shape = Path()
          ..moveTo(48, 68)
          ..cubicTo(68, 67, 83, 53, 82, 26)
          ..cubicTo(59, 27, 47, 43, 48, 68)
          ..close();
        canvas.drawPath(
          shape,
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Color.lerp(color, Colors.white, .2)!,
                Color.lerp(color, const Color(0xFF5FAD74), .25)!,
              ],
            ).createShader(const Rect.fromLTWH(48, 26, 34, 42)),
        );
        final vein = Paint()
          ..color = Colors.white.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.15
          ..strokeCap = StrokeCap.round;
        canvas.drawPath(
          Path()
            ..moveTo(49, 65)
            ..quadraticBezierTo(65, 48, 78, 31),
          vein,
        );
        canvas.drawPath(
          Path()
            ..moveTo(59, 53)
            ..quadraticBezierTo(66, 52, 73, 47),
          vein..strokeWidth = .7,
        );
        canvas.drawPath(
          Path()
            ..moveTo(68, 42)
            ..quadraticBezierTo(69, 35, 70, 32),
          vein,
        );
        canvas.restore();
      }
    }
    if (wheat > 0) {
      canvas.save();
      canvas.translate(48, 53);
      canvas.scale(wheat, wheat);
      canvas.translate(-48, -53);
      canvas.drawLine(
        const Offset(48, 54),
        const Offset(48, 15),
        Paint()
          ..color = accentColor
          ..strokeWidth = 1.7
          ..strokeCap = StrokeCap.round,
      );
      for (final y in [22.0, 29.0, 36.0, 43.0]) {
        for (final side in [-1.0, 1.0]) {
          canvas.save();
          canvas.translate(48, y);
          canvas.scale(side, 1);
          canvas.drawPath(
            Path()
              ..moveTo(1, 2)
              ..cubicTo(2, -3, 7, -6, 11, -5)
              ..cubicTo(11, 0, 6, 4, 1, 2)
              ..close(),
            Paint()..color = accentColor,
          );
          canvas.restore();
        }
      }
      canvas.drawPath(
        Path()
          ..moveTo(48, 19)
          ..cubicTo(43, 16, 45, 12, 48, 10)
          ..cubicTo(51, 12, 53, 16, 48, 19)
          ..close(),
        Paint()..color = accentColor,
      );
      canvas.restore();
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant HarvestSproutPainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      accentColor != oldDelegate.accentColor;
}
