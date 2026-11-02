import 'package:flutter/material.dart';

class ProduceIllustration extends StatelessWidget {
  const ProduceIllustration({super.key, required this.id, this.size = 70});
  final String id;
  final double size;
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _ProducePainter(id));
}

class _ProducePainter extends CustomPainter {
  const _ProducePainter(this.id);
  final String id;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100, size.height / 100);
    void oval(double x, double y, double w, double h, int color) =>
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x, y), width: w, height: h),
          Paint()..color = Color(color),
        );
    void line(
      double x,
      double y,
      double endX,
      double endY,
      int color,
      double width,
    ) => canvas.drawLine(
      Offset(x, y),
      Offset(endX, endY),
      Paint()
        ..color = Color(color)
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void leaf(double x, double y, double angle, {int color = 0xFF3C7547}) {
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(angle);
      canvas.drawPath(
        Path()
          ..moveTo(0, 0)
          ..quadraticBezierTo(-18, -16, 0, -30)
          ..quadraticBezierTo(18, -16, 0, 0),
        Paint()..color = Color(color),
      );
      canvas.restore();
    }

    oval(50, 91, 65, 7, 0x16000000);
    switch (id) {
      case 'tomato':
        oval(50, 58, 76, 65, 0xFFD74E3D);
        oval(36, 53, 37, 47, 0xFFEA6850);
        for (var i = 0; i < 5; i++) {
          leaf(50, 34, i * 1.25, color: 0xFF426B3A);
        }
        line(50, 31, 55, 12, 0xFF345D36, 5);
      case 'avocado':
        canvas.drawPath(
          Path()
            ..moveTo(50, 7)
            ..cubicTo(20, 7, 28, 26, 15, 52)
            ..cubicTo(-2, 97, 94, 107, 86, 59)
            ..cubicTo(83, 34, 74, 7, 50, 7)
            ..close(),
          Paint()..color = const Color(0xFF477A3C),
        );
        oval(50, 59, 60, 69, 0xFFD9E996);
        oval(50, 63, 32, 35, 0xFF98643F);
        oval(44, 57, 15, 16, 0xFFB6804F);
      case 'carrot':
        leaf(63, 25, -.6);
        leaf(63, 25, .6);
        leaf(63, 25, .1);
        canvas.drawPath(
          Path()
            ..moveTo(43, 27)
            ..quadraticBezierTo(73, 13, 82, 41)
            ..lineTo(20, 91)
            ..quadraticBezierTo(17, 91, 19, 82)
            ..close(),
          Paint()..color = const Color(0xFFEC8739),
        );
        line(42, 40, 52, 47, 0xFFC8662A, 3);
        line(36, 58, 44, 63, 0xFFC8662A, 3);
      case 'strawberry':
        canvas.drawPath(
          Path()
            ..moveTo(15, 35)
            ..cubicTo(16, 15, 83, 15, 85, 35)
            ..cubicTo(89, 58, 58, 94, 50, 94)
            ..cubicTo(41, 94, 10, 57, 15, 35),
          Paint()..color = const Color(0xFFD94B59),
        );
        for (var i = 0; i < 5; i++) {
          leaf(50, 29, (i - 2) * .65);
        }
        for (var i = 0; i < 4; i++) {
          for (var j = 0; j < 3; j++) {
            oval(32.0 + j * 17, 40.0 + i * 11, 3, 5, 0xFFFFD795);
          }
        }
      case 'cucumber':
        canvas.save();
        canvas.translate(50, 52);
        canvas.rotate(.55);
        oval(0, 0, 35, 83, 0xFF487947);
        line(-7, -30, -7, 28, 0xFF89AA62, 3);
        line(5, -30, 5, 28, 0xFF749C54, 3);
        canvas.restore();
        oval(73, 77, 34, 27, 0xFF3E6D3E);
        oval(73, 77, 27, 21, 0xFFDCEBB1);
        for (var i = 0; i < 3; i++) {
          oval(66.0 + i * 7, 77, 3, 6, 0xFFF7F5DB);
        }
      case 'potato':
        oval(37, 58, 57, 49, 0xFFC5A16D);
        oval(66, 67, 50, 41, 0xFFD8B782);
        for (final spot in [
          const Offset(24, 50),
          const Offset(42, 65),
          const Offset(62, 61),
          const Offset(77, 76),
        ]) {
          oval(spot.dx, spot.dy, 4, 3, 0xFFA28256);
        }
      case 'apple':
        oval(36, 56, 47, 64, 0xFFD55349);
        oval(63, 56, 47, 64, 0xFFC3443D);
        oval(28, 45, 10, 23, 0xFFF1A18B);
        line(50, 30, 54, 12, 0xFF785A37, 5);
        leaf(54, 23, 1.1);
      case 'banana':
        for (var i = 0; i < 3; i++) {
          canvas.drawPath(
            Path()
              ..moveTo(20.0 + i * 7, 24)
              ..quadraticBezierTo(19.0 + i * 6, 69, 82, 41.0 + i * 7)
              ..quadraticBezierTo(69, 99, 34.0 + i * 7, 79)
              ..quadraticBezierTo(12.0 + i * 6, 64, 20.0 + i * 7, 24),
            Paint()..color = Color([0xFFE1B849, 0xFFF0CA57, 0xFFF7DA77][i]),
          );
        }
        line(29, 24, 32, 15, 0xFF766940, 6);
      case 'butter':
      case 'paneer':
        oval(50, 81, 88, 16, 0xFFD3DDD1);
        final dairyColor = id == 'butter' ? 0xFFE9CB6E : 0xFFE3DEBF;
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(18, 46, 66, 32),
            const Radius.circular(5),
          ),
          Paint()..color = Color(dairyColor),
        );
        canvas.drawPath(
          Path()
            ..moveTo(18, 46)
            ..lineTo(35, 31)
            ..lineTo(91, 31)
            ..lineTo(84, 46)
            ..close(),
          Paint()..color = Color(id == 'butter' ? 0xFFFFE8A2 : 0xFFFFF8DD),
        );
        if (id == 'paneer') {
          line(40, 46, 40, 77, 0xFFC5C2A6, 2);
          line(62, 46, 62, 77, 0xFFC5C2A6, 2);
        }
      case 'corn':
        oval(51, 47, 38, 72, 0xFFE5BC4B);
        for (var row = 0; row < 7; row++) {
          for (var col = 0; col < 3; col++) {
            oval(41.0 + col * 10, 21.0 + row * 9, 8, 7, 0xFFFFDD76);
          }
        }
        canvas.drawPath(
          Path()
            ..moveTo(50, 93)
            ..quadraticBezierTo(9, 76, 13, 38)
            ..quadraticBezierTo(39, 50, 50, 93),
          Paint()..color = const Color(0xFF658D46),
        );
        canvas.drawPath(
          Path()
            ..moveTo(50, 93)
            ..quadraticBezierTo(86, 78, 88, 43)
            ..quadraticBezierTo(61, 52, 50, 93),
          Paint()..color = const Color(0xFF85A756),
        );
      case 'milk':
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(27, 21, 47, 70),
            const Radius.circular(12),
          ),
          Paint()..color = const Color(0xFFFFFEF7),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            const Rect.fromLTWH(33, 8, 35, 17),
            const Radius.circular(4),
          ),
          Paint()..color = const Color(0xFF638799),
        );
        canvas.drawRect(
          const Rect.fromLTWH(28, 48, 45, 23),
          Paint()..color = const Color(0xFF8DAAA9),
        );
        oval(50, 60, 15, 15, 0xFFFFFEF7);
      case 'wheat':
        for (var i = 0; i < 3; i++) {
          final x = 28.0 + i * 23;
          line(x, 90, x, 18, 0xFFB28A3F, 3);
          for (var j = 0; j < 4; j++) {
            leaf(x, 65.0 - j * 13, -.65, color: 0xFFDDB665);
            leaf(x, 65.0 - j * 13, .65, color: 0xFFC99C4F);
          }
        }
      case 'basil':
      case 'mint':
      case 'coriander':
      case 'rosemary':
        line(50, 92, 50, 20, 0xFF3B693C, 4);
        if (id == 'rosemary') {
          for (var i = 0; i < 7; i++) {
            line(50, 82.0 - i * 9, 34, 67.0 - i * 9, 0xFF678670, 4);
            line(50, 82.0 - i * 9, 66, 67.0 - i * 9, 0xFF507659, 4);
          }
        } else {
          final shade = id == 'mint'
              ? 0xFF408463
              : id == 'coriander'
              ? 0xFF80A14D
              : 0xFF5D9253;
          for (var i = 0; i < 3; i++) {
            leaf(50, 80.0 - i * 22, -1, color: shade);
            leaf(50, 75.0 - i * 22, 1, color: 0xFF40733E);
          }
          leaf(50, 36, 0, color: shade);
        }
      default:
        canvas.drawPath(
          Path()
            ..moveTo(10, 52)
            ..lineTo(90, 52)
            ..quadraticBezierTo(86, 92, 50, 92)
            ..quadraticBezierTo(14, 92, 10, 52),
          Paint()..color = const Color(0xFFB67A55),
        );
        oval(50, 52, 80, 28, 0xFFEAD4AD);
        if (id == 'yogurt') {
          oval(50, 51, 72, 24, 0xFFFFFCED);
          oval(48, 51, 46, 13, 0xFFEDE8D9);
          oval(49, 49, 41, 10, 0xFFFFFCED);
          break;
        }
        final (light, dark) = switch (id) {
          'rice' => (0xFFFFFAE8, 0xFFE6DDC4),
          'oats' => (0xFFE6CCA0, 0xFFC5A779),
          'chickpea' => (0xFFEBC890, 0xFFD2AA70),
          'kidneybean' => (0xFF9C514B, 0xFF793E3C),
          'mung' => (0xFF84965B, 0xFF667843),
          _ => (0xFFD57D4A, 0xFFBD653D),
        };
        for (var i = 0; i < 20; i++) {
          oval(
            23 + (i * 13 % 56).toDouble(),
            46 + (i * 7 % 14).toDouble(),
            id == 'rice' ? 3 : 9,
            id == 'chickpea' ? 8 : 5,
            i.isEven ? light : dark,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ProducePainter oldDelegate) =>
      oldDelegate.id != id;
}
