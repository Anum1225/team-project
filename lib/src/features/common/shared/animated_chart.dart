import 'package:flutter/material.dart';

import '../data/models.dart';
import 'theme.dart';

enum ChartMode { spline, bars }

/// Awards-level interactive animated chart with cubic spline curve, glowing area
/// gradient, pulsing data nodes, touch scrubbing, and bar/spline toggle.
class AnimatedHarvestChart extends StatefulWidget {
  const AnimatedHarvestChart({
    super.key,
    required this.values,
    this.initialMode = ChartMode.spline,
  });

  final List<double> values;
  final ChartMode initialMode;

  @override
  State<AnimatedHarvestChart> createState() => _AnimatedHarvestChartState();
}

class _AnimatedHarvestChartState extends State<AnimatedHarvestChart>
    with SingleTickerProviderStateMixin {
  late ChartMode _mode = widget.initialMode;
  int? _hoveredIndex;
  late final AnimationController _drawController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  late final Animation<double> _drawCurved = CurvedAnimation(
    parent: _drawController,
    curve: Curves.easeOutCubic,
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (MediaQuery.disableAnimationsOf(context)) {
          _drawController.value = 1.0;
        } else {
          _drawController.forward();
        }
      }
    });
  }

  @override
  void didUpdateWidget(AnimatedHarvestChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.values != widget.values) {
      if (!MediaQuery.disableAnimationsOf(context)) {
        _drawController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _drawController.dispose();
    super.dispose();
  }

  void _handleTouch(Offset localPosition, double width) {
    if (widget.values.isEmpty || width <= 0) return;
    final step = width / widget.values.length;
    final index = (localPosition.dx / step).floor().clamp(
      0,
      widget.values.length - 1,
    );
    if (_hoveredIndex != index) {
      setState(() => _hoveredIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final peak = values.fold<double>(0, (a, b) => a > b ? a : b);
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Semantics(
      label: 'Daily order values, oldest to newest',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header with Active Value Pill and Mode Toggle
          Row(
            children: [
              if (_hoveredIndex != null && _hoveredIndex! < values.length) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: palette.freshLeaf.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: palette.freshLeaf.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: palette.freshLeaf,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Day ${_hoveredIndex! + 1}: ${money(values[_hoveredIndex!].toInt())}',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : palette.forest,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Text(
                  peak > 0 ? 'Peak: ${money(peak.toInt())}' : 'No activity',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: palette.muted,
                  ),
                ),
              ],
              const Spacer(),
              // Toggle Spline / Bars
              Container(
                height: 28,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1B261F)
                      : const Color(0xFFEBF1ED),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.all(2),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ModeIconButton(
                      icon: Icons.show_chart_rounded,
                      tooltip: 'Wave area view',
                      selected: _mode == ChartMode.spline,
                      palette: palette,
                      onTap: () => setState(() => _mode = ChartMode.spline),
                    ),
                    const SizedBox(width: 2),
                    _ModeIconButton(
                      icon: Icons.bar_chart_rounded,
                      tooltip: 'Column bar view',
                      selected: _mode == ChartMode.bars,
                      palette: palette,
                      onTap: () => setState(() => _mode = ChartMode.bars),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Main Chart Canvas with interactive scrub gesture
          SizedBox(
            height: 180,
            child: peak == 0
                ? Center(
                    child: Text(
                      'No order value recorded in this period.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: palette.muted,
                        fontSize: 13,
                      ),
                    ),
                  )
                : LayoutBuilder(
                    builder: (context, constraints) {
                      return GestureDetector(
                        onHorizontalDragUpdate: (details) => _handleTouch(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        onHorizontalDragStart: (details) => _handleTouch(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        onTapDown: (details) => _handleTouch(
                          details.localPosition,
                          constraints.maxWidth,
                        ),
                        onTapUp: (_) =>
                            Future.delayed(const Duration(seconds: 2), () {
                              if (mounted) setState(() => _hoveredIndex = null);
                            }),
                        child: AnimatedBuilder(
                          animation: _drawCurved,
                          builder: (context, _) {
                            final progress = _drawCurved.value;
                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Background subtle horizontal gridlines
                                Positioned.fill(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: List.generate(
                                      4,
                                      (i) => Divider(
                                        color: palette.border.withValues(
                                          alpha: 0.6,
                                        ),
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),

                                // Custom Chart Renderer
                                if (_mode == ChartMode.spline)
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: _SplineChartPainter(
                                        values: values,
                                        peak: peak,
                                        progress: progress,
                                        palette: palette,
                                        hoveredIndex: _hoveredIndex,
                                        isDark: isDark,
                                      ),
                                    ),
                                  )
                                else
                                  Positioned.fill(
                                    child: _AnimatedBarChart(
                                      values: values,
                                      peak: peak,
                                      progress: progress,
                                      palette: palette,
                                      hoveredIndex: _hoveredIndex,
                                      onHover: (idx) =>
                                          setState(() => _hoveredIndex = idx),
                                    ),
                                  ),

                                // Interactive floating tooltip
                                if (_hoveredIndex != null &&
                                    _hoveredIndex! < values.length) ...[
                                  _ChartTooltipOverlay(
                                    index: _hoveredIndex!,
                                    totalItems: values.length,
                                    value: values[_hoveredIndex!],
                                    peak: peak,
                                    width: constraints.maxWidth,
                                    palette: palette,
                                    isDark: isDark,
                                  ),
                                ],
                              ],
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),

          // Day X-Axis labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              values.length,
              (i) => Expanded(
                child: Center(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 180),
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 11,
                      fontWeight: _hoveredIndex == i
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: _hoveredIndex == i
                          ? (isDark ? Colors.white : palette.forest)
                          : palette.muted,
                    ),
                    child: Text('D${i + 1}'),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeIconButton extends StatelessWidget {
  const _ModeIconButton({
    required this.icon,
    required this.tooltip,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final bool selected;
  final HarvestPalette palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: selected ? palette.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Icon(
          icon,
          size: 16,
          color: selected ? palette.green : palette.muted,
        ),
      ),
    ),
  );
}

/// Floating glassmorphic tooltip card that tracks the scrub position
class _ChartTooltipOverlay extends StatelessWidget {
  const _ChartTooltipOverlay({
    required this.index,
    required this.totalItems,
    required this.value,
    required this.peak,
    required this.width,
    required this.palette,
    required this.isDark,
  });

  final int index;
  final int totalItems;
  final double value;
  final double peak;
  final double width;
  final HarvestPalette palette;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final step = width / totalItems;
    final x = (index * step + step / 2).clamp(50.0, width - 50.0);

    return Positioned(
      left: x - 45,
      top: -10,
      child: IgnorePointer(
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 180),
          tween: Tween(begin: 0.8, end: 1.0),
          curve: Curves.easeOutBack,
          builder: (context, scale, child) =>
              Transform.scale(scale: scale, child: child),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2F24) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: palette.freshLeaf.withValues(alpha: 0.40),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.16),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Day ${index + 1}',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: palette.muted,
                  ),
                ),
                Text(
                  money(value.toInt()),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : palette.forest,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Smooth cubic bezier spline chart painter with radiant gradient fill and nodes
class _SplineChartPainter extends CustomPainter {
  _SplineChartPainter({
    required this.values,
    required this.peak,
    required this.progress,
    required this.palette,
    required this.hoveredIndex,
    required this.isDark,
  });

  final List<double> values;
  final double peak;
  final double progress;
  final HarvestPalette palette;
  final int? hoveredIndex;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty || peak <= 0) return;

    final n = values.length;
    final step = size.width / (n > 1 ? (n - 1) : 1);
    final points = <Offset>[];

    for (var i = 0; i < n; i++) {
      final x = n == 1 ? size.width / 2 : i * step;
      final normalized = (values[i] / peak).clamp(0.0, 1.0);
      final y = size.height - (normalized * (size.height - 24) + 8) * progress;
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    // Build smooth cubic bezier curve
    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    for (var i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      final midX = (p0.dx + p1.dx) / 2;
      path.cubicTo(midX, p0.dy, midX, p1.dy, p1.dx, p1.dy);
    }

    // 1. Draw glowing radiant area beneath the curve
    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          palette.freshLeaf.withValues(alpha: isDark ? 0.38 : 0.28),
          palette.green.withValues(alpha: isDark ? 0.08 : 0.03),
          Colors.transparent,
        ],
        stops: const [0.0, 0.65, 1.0],
      ).createShader(Offset.zero & size)
      ..style = PaintingStyle.fill;

    canvas.drawPath(areaPath, areaPaint);

    // 2. Draw glowing primary spline stroke
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [palette.green, palette.freshLeaf],
      ).createShader(Offset.zero & size);

    canvas.drawPath(path, strokePaint);

    // 3. Draw vertical hover guide and highlighted node if scrubbing
    if (hoveredIndex != null && hoveredIndex! < points.length) {
      final hp = points[hoveredIndex!];

      // Vertical guide line
      final guidePaint = Paint()
        ..color = palette.freshLeaf.withValues(alpha: 0.45)
        ..strokeWidth = 1.5;
      canvas.drawLine(Offset(hp.dx, 0), Offset(hp.dx, size.height), guidePaint);

      // Glowing outer ring on active node
      final glowPaint = Paint()
        ..color = palette.freshLeaf.withValues(alpha: 0.30)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(hp, 14, glowPaint);
    }

    // 4. Draw data nodes
    final nodeFillPaint = Paint()
      ..color = isDark ? const Color(0xFF0F1E16) : Colors.white
      ..style = PaintingStyle.fill;

    final nodeStrokePaint = Paint()
      ..color = palette.freshLeaf
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 0; i < points.length; i++) {
      final p = points[i];
      final isHovered = hoveredIndex == i;
      final radius = isHovered ? 6.5 : 4.0;

      canvas.drawCircle(p, radius, nodeFillPaint);
      canvas.drawCircle(
        p,
        radius,
        isHovered
            ? (Paint()
                ..color = Colors.white
                ..style = PaintingStyle.stroke
                ..strokeWidth = 3.0)
            : nodeStrokePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SplineChartPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.hoveredIndex != hoveredIndex ||
      oldDelegate.values != values ||
      oldDelegate.isDark != isDark;
}

/// Animated column bars with rounded caps, gradient fill and interactive hover
class _AnimatedBarChart extends StatelessWidget {
  const _AnimatedBarChart({
    required this.values,
    required this.peak,
    required this.progress,
    required this.palette,
    required this.hoveredIndex,
    required this.onHover,
  });

  final List<double> values;
  final double peak;
  final double progress;
  final HarvestPalette palette;
  final int? hoveredIndex;
  final ValueChanged<int> onHover;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(values.length, (i) {
        final heightFactor = (values[i] / peak).clamp(0.0, 1.0) * progress;
        final isHovered = hoveredIndex == i;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: InkWell(
              onTap: () => onHover(i),
              borderRadius: BorderRadius.circular(10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 160 * heightFactor + 4,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isHovered
                        ? [palette.honey, palette.freshLeaf]
                        : [palette.freshLeaf, palette.green],
                  ),
                  boxShadow: isHovered
                      ? [
                          BoxShadow(
                            color: palette.freshLeaf.withValues(alpha: 0.45),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
