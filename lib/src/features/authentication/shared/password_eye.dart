part of '../authentication.dart';

class PasswordEye extends StatelessWidget {
  const PasswordEye({super.key, required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(end: open ? 1.0 : 0.0),
    duration: MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : const Duration(milliseconds: 260),
    curve: Curves.easeInOutCubic,
    builder: (context, value, _) => CustomPaint(
      size: const Size(24, 24),
      painter: _EyePainter(value, Harvest.colors(context).muted),
    ),
  );
}

class _EyePainter extends CustomPainter {
  const _EyePainter(this.openness, this.color);
  final double openness;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    final stroke = Paint()
      ..color = color
      ..strokeWidth = 1.7
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final top = 15 - 13 * openness;
    final bottom = 15 + 7 * openness;
    final eye = Path()
      ..moveTo(2, 12)
      ..quadraticBezierTo(12, top, 22, 12)
      ..quadraticBezierTo(12, bottom, 2, 12);
    canvas.drawPath(eye, stroke);
    if (openness > 0.05) {
      canvas.drawCircle(
        const Offset(12, 12),
        3 * openness,
        Paint()..color = color.withValues(alpha: openness),
      );
      canvas.drawCircle(
        const Offset(13, 11),
        0.8 * openness,
        Paint()..color = Colors.white.withValues(alpha: openness),
      );
    }
    final lashStroke = Paint()
      ..color = color.withValues(alpha: 1 - openness)
      ..strokeWidth = 1.7
      ..strokeCap = StrokeCap.round;
    for (final x in [6.0, 12.0, 18.0]) {
      final y = x == 12 ? 13.5 : 13.0;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + (x - 12) * 0.12, y + 3 * (1 - openness)),
        lashStroke,
      );
    }
  }

  @override
  bool shouldRepaint(_EyePainter old) =>
      old.openness != openness || old.color != color;
}
