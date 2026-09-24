import 'package:flutter/material.dart';

import 'dart:math' as math;

import 'store.dart';

const green = Color(0xFF234D35);
const canvas = Color(0xFFF8F9F4);
const muted = Color(0xFF747E72);
const lime = Color(0xFFE4EDB5);

/// A bundled, resolution-independent farm illustration; no network required.
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

ThemeData customerTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: canvas,
  colorScheme: ColorScheme.fromSeed(
    seedColor: green,
    primary: green,
    surface: canvas,
  ),
  fontFamily: 'Roboto',
  appBarTheme: const AppBarTheme(
    backgroundColor: canvas,
    foregroundColor: green,
    elevation: 0,
    centerTitle: false,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 50),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.all(17),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE2D7)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: Color(0xFFDCE2D7)),
    ),
  ),
  dividerTheme: const DividerThemeData(color: Color(0xFFE3E7DD), space: 28),
);

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(MaterialPageRoute(builder: (_) => page));

class PageFrame extends StatelessWidget {
  const PageFrame({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
  });
  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      actions: actions,
    ),
    body: SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1040),
          child: child,
        ),
      ),
    ),
    bottomNavigationBar: bottom == null
        ? null
        : SafeArea(
            child: Padding(padding: const EdgeInsets.all(18), child: bottom),
          ),
  );
}

class Heading extends StatelessWidget {
  const Heading(this.title, {super.key, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 18, top: 8),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: green,
                  letterSpacing: -.7,
                ),
              ),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 5),
                  child: Text(
                    subtitle!,
                    style: const TextStyle(color: muted, height: 1.5),
                  ),
                ),
            ],
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

class Surface extends StatelessWidget {
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) => Material(
    color: color,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE6EADF)),
    ),
    child: Padding(padding: padding, child: child),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState(
    this.icon,
    this.title,
    this.message, {
    super.key,
    this.action,
  });
  final IconData icon;
  final String title, message;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundColor: lime,
            child: Icon(icon, size: 40, color: green),
          ),
          const SizedBox(height: 22),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: green,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted, height: 1.6),
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 22), child: action!),
        ],
      ),
    ),
  );
}

class ProductArt extends StatelessWidget {
  const ProductArt(this.product, {super.key, this.size = 70});
  final Product product;
  final double size;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Color(product.color),
      borderRadius: BorderRadius.circular(15),
    ),
    alignment: Alignment.center,
    child: Semantics(
      label: product.name,
      image: true,
      child: ProduceIllustration(id: product.id, size: size),
    ),
  );
}

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
        line(50, 92, 50, 20, 0xFF3B693C, 4);
        for (var i = 0; i < 3; i++) {
          leaf(50, 80.0 - i * 22, -1, color: 0xFF5D9253);
          leaf(50, 75.0 - i * 22, 1, color: 0xFF40733E);
        }
        leaf(50, 36, 0, color: 0xFF739E56);
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
        for (var i = 0; i < 20; i++) {
          oval(
            23 + (i * 13 % 56).toDouble(),
            46 + (i * 7 % 14).toDouble(),
            9,
            5,
            i.isEven ? 0xFFD57D4A : 0xFFBD653D,
          );
        }
    }
  }

  @override
  bool shouldRepaint(covariant _ProducePainter oldDelegate) =>
      oldDelegate.id != id;
}

class Tag extends StatelessWidget {
  const Tag(this.label, {super.key, this.color = lime});
  final String label;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: green,
      ),
    ),
  );
}

class QuantityPicker extends StatelessWidget {
  const QuantityPicker({
    super.key,
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = 0,
  });
  final int value, max, min;
  final ValueChanged<int> onChanged;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Decrease quantity',
        onPressed: value > min ? () => onChanged(value - 1) : null,
        icon: const Icon(Icons.remove_circle_outline),
      ),
      Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
      IconButton(
        tooltip: 'Increase quantity',
        onPressed: value < max ? () => onChanged(value + 1) : null,
        icon: const Icon(Icons.add_circle_outline),
      ),
    ],
  );
}

class PriceRow extends StatelessWidget {
  const PriceRow(this.label, this.value, {super.key, this.bold = false});
  final String label, value;
  final bool bold;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              color: bold ? green : muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: bold ? 21 : 15,
            color: green,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}
