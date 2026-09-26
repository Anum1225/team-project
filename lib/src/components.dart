import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'models.dart';
import 'store.dart';
import 'theme.dart';
import 'voice_search.dart';
import 'animated_chart.dart';

class HarvestScope extends InheritedNotifier<HarvestStore> {
  const HarvestScope({
    super.key,
    required HarvestStore store,
    required super.child,
  }) : super(notifier: store);

  static HarvestStore of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<HarvestScope>()!.notifier!;
}

Future<T?> openPage<T>(BuildContext context, Widget page) =>
    Navigator.of(context).push<T>(
      PageRouteBuilder<T>(
        transitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Harvest.routeMotion,
        reverseTransitionDuration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : Harvest.motion,
        pageBuilder: (_, animation, secondary) => page,
        transitionsBuilder: (_, animation, secondary, child) {
          final curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curve,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.03),
                end: Offset.zero,
              ).animate(curve),
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.985, end: 1.0).animate(curve),
                child: child,
              ),
            ),
          );
        },
      ),
    );

void notice(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.info_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? Harvest.danger : Harvest.forest,
        duration: const Duration(milliseconds: 2400),
      ),
    );
}

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool isDestructive = false,
}) async =>
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SheetBody(
        children: [
          Text(title, style: Harvest.editorial(26)),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Harvest.colors(context).muted,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          HarvestButton(
            label: action,
            color: isDestructive ? Harvest.danger : Harvest.forest,
            onPressed: () => Navigator.pop(context, true),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it as it is'),
          ),
        ],
      ),
    ) ??
    false;

class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            24,
            8,
            24,
            24 + MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    ),
  );
}

class HarvestButton extends StatefulWidget {
  const HarvestButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.outlined = false,
    this.busy = false,
    this.color,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined, busy;
  final Color? color;
  final double height;

  @override
  State<HarvestButton> createState() => _HarvestButtonState();
}

class _HarvestButtonState extends State<HarvestButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.color ?? Harvest.forest;
    final content = AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: Harvest.microMotion,
      curve: Curves.easeOutCubic,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.busy) ...[
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
          ] else if (widget.icon != null) ...[
            Icon(widget.icon, size: 19),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              widget.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: widget.outlined
          ? OutlinedButton(
              onPressed: widget.busy ? null : widget.onPressed,
              style: OutlinedButton.styleFrom(
                minimumSize: Size(48, widget.height),
                side: BorderSide(color: effectiveColor, width: 1.2),
                foregroundColor: effectiveColor,
              ),
              child: content,
            )
          : FilledButton(
              onPressed: widget.busy ? null : widget.onPressed,
              style: FilledButton.styleFrom(
                minimumSize: Size(48, widget.height),
                backgroundColor: effectiveColor,
              ),
              child: content,
            ),
    );
  }
}

class HarvestPage extends StatelessWidget {
  const HarvestPage({
    super.key,
    required this.title,
    required this.child,
    this.actions,
    this.bottom,
    this.backgroundColor,
  });

  final String title;
  final Widget child;
  final List<Widget>? actions;
  final Widget? bottom;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: backgroundColor ?? Harvest.colors(context).cream,
    appBar: AppBar(
      title: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
      ),
      actions: actions,
    ),
    body: SafeArea(top: false, child: child),
    bottomNavigationBar: bottom == null ? null : BottomAction(child: bottom!),
  );
}

class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Harvest.colors(context).cream,
      border: Border(
        top: BorderSide(color: Harvest.colors(context).border, width: 1),
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0A14281C),
          blurRadius: 16,
          offset: Offset(0, -4),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
        child: child,
      ),
    ),
  );
}

class PageHeading extends StatelessWidget {
  const PageHeading(
    this.title, {
    super.key,
    this.eyebrow,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? eyebrow, subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 22),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (eyebrow != null) ...[
                Eyebrow(eyebrow!),
                const SizedBox(height: 8),
              ],
              Text(title, style: Harvest.editorial(32)),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: TextStyle(
                    color: Harvest.colors(context).muted,
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    ),
  );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = Harvest.green});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.6,
      color: color,
    ),
  );
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.onAction,
    this.icon,
    this.subtitle,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: Harvest.colors(context).green),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(title, style: Harvest.editorial(23))),
        if (action != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(40, 36),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  action!,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.arrow_forward, size: 14),
              ],
            ),
          ),
      ],
    ),
  );
}

class Photo extends StatefulWidget {
  const Photo(
    this.asset, {
    super.key,
    this.bytes,
    this.height,
    this.width,
    this.radius = 20,
    this.label,
    this.fit = BoxFit.cover,
  });

  final String asset;
  final Uint8List? bytes;
  final double? height, width;
  final double radius;
  final String? label;
  final BoxFit fit;

  @override
  State<Photo> createState() => _PhotoState();
}

class _PhotoState extends State<Photo> {
  Uint8List? _decoded;
  String? _decodedFrom;

  Uint8List? _memoryBytes() {
    if (widget.bytes != null) return widget.bytes;
    final asset = widget.asset;
    if (!asset.startsWith('data:image/jpeg;base64,')) return null;
    if (_decoded == null || _decodedFrom != asset) {
      _decodedFrom = asset;
      _decoded = base64Decode(asset.substring(23));
    }
    return _decoded;
  }

  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext context, Object error, StackTrace? stack) =>
        Container(
          height: widget.height,
          width: widget.width,
          decoration: BoxDecoration(
            color: Harvest.colors(context).paleLeaf,
            borderRadius: BorderRadius.circular(widget.radius),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.spa_outlined,
            color: Harvest.colors(context).green,
            size: 30,
          ),
        );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final dpr = MediaQuery.devicePixelRatioOf(context);
          final w = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (widget.width ?? 0);
          final h = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (widget.height ?? 0);
          final side = (w > h ? w : h) * dpr;
          final cacheWidth = side <= 0
              ? null
              : (side > 1200 ? 1200 : side).ceil();
          final bytes = _memoryBytes();
          final asset = widget.asset;
          Widget image;
          if (bytes != null) {
            image = Image.memory(
              bytes,
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              semanticLabel: widget.label,
              errorBuilder: fallback,
              cacheWidth: cacheWidth,
            );
          } else if (asset.startsWith('http')) {
            image = Image.network(
              asset,
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              semanticLabel: widget.label,
              errorBuilder: fallback,
              cacheWidth: cacheWidth,
            );
          } else {
            image = Image.asset(
              'assets/images/$asset.jpg',
              height: widget.height,
              width: widget.width,
              fit: widget.fit,
              semanticLabel: widget.label,
              errorBuilder: fallback,
              cacheWidth: 800,
            );
          }
          return image;
        },
      ),
    );
  }
}

class SeedMark extends StatelessWidget {
  const SeedMark({super.key, this.size = 42, this.color = Harvest.forest});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'HarvestHub seed mark',
    image: true,
    child: SizedBox(
      width: size,
      height: size,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/app_logo.png',
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => CustomPaint(
            size: Size.square(size),
            painter: _SeedPainter(color),
          ),
        ),
      ),
    ),
  );
}

class _SeedPainter extends CustomPainter {
  _SeedPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 48, size.height / 48);
    final paint = Paint()..color = color;

    // Organic left leaf/seed shape
    final leftLeaf = Path()
      ..moveTo(24, 38)
      ..cubicTo(7, 37, 4, 21, 7, 12)
      ..cubicTo(23, 11, 26, 23, 24, 38);
    canvas.drawPath(leftLeaf, paint);

    // Organic right leaf shape
    final rightLeaf = Path()
      ..moveTo(26, 28)
      ..cubicTo(24, 13, 34, 5, 43, 5)
      ..cubicTo(45, 19, 39, 29, 26, 28);
    canvas.drawPath(rightLeaf, paint);

    // Delicate curved stem
    final stem = Path()
      ..moveTo(24, 44)
      ..quadraticBezierTo(25.5, 31, 31, 22);
    canvas.drawPath(
      stem,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_SeedPainter oldDelegate) => oldDelegate.color != color;
}

/// Official HarvestHub top brand navigation header matching reference design
class HarvestHubBrandHeader extends StatelessWidget {
  const HarvestHubBrandHeader({
    super.key,
    required this.marketName,
    this.onLocationTap,
    this.onNotificationTap,
    this.onProfileTap,
    this.unreadNotifications = true,
  });

  final String marketName;
  final VoidCallback? onLocationTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;
  final bool unreadNotifications;

  @override
  Widget build(BuildContext context) {
    final palette = Harvest.colors(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Logo emblem
          const SeedMark(size: 34),
          const SizedBox(width: 8),

          // Title & Location
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Harvest',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : palette.forest,
                            ),
                          ),
                          const TextSpan(
                            text: 'H',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFD97706),
                            ),
                          ),
                          TextSpan(
                            text: 'ub',
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : palette.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD1FAE5),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'eGreen',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF047857),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onLocationTap,
                  borderRadius: BorderRadius.circular(6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: palette.green,
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          marketName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: palette.muted,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 14,
                        color: palette.muted,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Notification Bell
          IconButton(
            onPressed: onNotificationTap,
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  Icons.notifications_none_rounded,
                  size: 24,
                  color: isDark ? Colors.white : palette.ink,
                ),
                if (unreadNotifications)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // User Avatar Button
          InkWell(
            onTap: onProfileTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: palette.forest,
                border: Border.all(
                  color: const Color(0xFF10B981).withValues(alpha: 0.35),
                  width: 1.5,
                ),
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 20,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.eco_outlined,
    this.action,
    this.onAction,
  });

  final String title, message;
  final IconData icon;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Harvest.colors(context).paleLeaf,
            shape: BoxShape.circle,
            border: Border.all(
              color: Harvest.colors(context).border,
              width: 1.5,
            ),
          ),
          child: Icon(icon, size: 36, color: Harvest.colors(context).green),
        ),
        const SizedBox(height: 22),
        Text(title, style: Harvest.editorial(26), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Harvest.colors(context).muted,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: 24),
          HarvestButton(label: action!, onPressed: onAction),
        ],
      ],
    ),
  );
}

class InfoNote extends StatelessWidget {
  const InfoNote(this.text, {super.key, this.error = false, this.icon});
  final String text;
  final bool error;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: error ? const Color(0xFFFBECE7) : Harvest.colors(context).paleLeaf,
      borderRadius: Harvest.radiusMd,
      border: Border.all(
        color: error ? const Color(0xFFF1D2C9) : Harvest.colors(context).border,
        width: 1,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon ?? (error ? Icons.error_outline : Icons.info_outline),
          size: 19,
          color: error ? Harvest.danger : Harvest.forest,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: error ? Harvest.danger : Harvest.forest,
            ),
          ),
        ),
      ],
    ),
  );
}

class SearchBox extends StatelessWidget {
  const SearchBox({
    super.key,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.hint = 'Search fresh produce, farmers, markets…',
    this.onTap,
    this.readOnly = false,
    this.autofocus = false,
    this.voiceSearch = false,
  });

  final TextEditingController? controller;
  final ValueChanged<String>? onChanged, onSubmitted;
  final String hint;
  final VoidCallback? onTap;
  final bool readOnly, autofocus;
  final bool voiceSearch;

  @override
  Widget build(BuildContext context) => Container(
    decoration: const BoxDecoration(
      borderRadius: Harvest.radiusMd,
      boxShadow: [
        BoxShadow(
          color: Color(0x0814281C),
          blurRadius: 12,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: TextField(
      controller: controller,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      autofocus: autofocus,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search,
          size: 22,
          color: Harvest.colors(context).green,
        ),
        hintText: hint,
        hintStyle: TextStyle(
          fontSize: 13,
          color: Harvest.colors(context).muted,
        ),
        fillColor: Harvest.colors(context).surface,
        suffixIcon:
            voiceSearch || (controller != null && controller!.text.isNotEmpty)
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (controller != null && controller!.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search',
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        controller!.clear();
                        onChanged?.call('');
                      },
                    ),
                  if (voiceSearch)
                    VoiceSearchControl(
                      onText: (value) {
                        if (controller != null) controller!.text = value;
                        onChanged?.call(value);
                        onSubmitted?.call(value);
                      },
                    ),
                  const SizedBox(width: 6),
                ],
              )
            : null,
      ),
    ),
  );
}

class ChoiceRow extends StatelessWidget {
  const ChoiceRow({
    super.key,
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    child: Row(
      children: [
        for (final value in values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(value),
              selected: selected == value,
              selectedColor: Harvest.forest,
              backgroundColor: Harvest.colors(context).surface,
              labelStyle: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected == value
                    ? Colors.white
                    : Harvest.colors(context).ink,
              ),
              side: BorderSide(
                color: selected == value
                    ? Harvest.forest
                    : Harvest.colors(context).border,
                width: 1.2,
              ),
              onSelected: (_) => onSelected(value),
            ),
          ),
      ],
    ),
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(
    this.label, {
    super.key,
    this.warning = false,
    this.success = false,
    this.icon = Icons.check_circle_outline,
  });

  final String label;
  final bool warning;
  final bool success;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    Color bg = Harvest.colors(context).paleLeaf;
    Color fg = Harvest.forest;
    if (warning) {
      bg = const Color(0xFFFDEFD9);
      fg = const Color(0xFFB5701B);
    } else if (success) {
      bg = const Color(0xFFE5F4E9);
      fg = Harvest.success;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: fg.withValues(alpha: 0.2), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: fg),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class QuantityStepper extends StatelessWidget {
  const QuantityStepper({
    super.key,
    required this.value,
    required this.onChanged,
    required this.max,
    this.min = 0,
  });

  final int value, max, min;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Harvest.colors(context).surface,
      border: Border.all(color: Harvest.colors(context).border, width: 1.2),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Decrease quantity',
          onPressed: value > min
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value - 1);
                }
              : null,
          icon: const Icon(Icons.remove, size: 16),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: EdgeInsets.zero,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 28),
          alignment: Alignment.center,
          child: AnimatedSwitcher(
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : Harvest.microMotion,
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              '$value',
              key: ValueKey(value),
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
            ),
          ),
        ),
        IconButton(
          tooltip: 'Increase quantity',
          onPressed: value < max
              ? () {
                  HapticFeedback.selectionClick();
                  onChanged(value + 1);
                }
              : null,
          icon: const Icon(Icons.add, size: 16),
          constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
          padding: EdgeInsets.zero,
        ),
      ],
    ),
  );
}

class ProductCard extends StatefulWidget {
  const ProductCard({super.key, required this.product, required this.onOpen});
  final Product product;
  final VoidCallback onOpen;

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final p = widget.product;
    final saved = store.saved.contains(p.id);

    return AnimatedScale(
      scale: _pressed ? 0.98 : 1.0,
      duration: Harvest.microMotion,
      curve: Curves.easeOutCubic,
      child: Container(
        decoration: BoxDecoration(
          color: Harvest.colors(context).surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Harvest.colors(context).border, width: 1),
          boxShadow: Harvest.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: widget.onOpen,
              onHighlightChanged: (val) => setState(() => _pressed = val),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 1.15,
                          child: Photo(
                            p.image,
                            bytes: p.photo,
                            width: double.infinity,
                            radius: 14,
                            label: p.name,
                          ),
                        ),
                        if (store.role == UserRole.customer)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Tooltip(
                              message: saved
                                  ? 'Unsave ${p.name}'
                                  : 'Save ${p.name}',
                              child: Material(
                                color: Colors.white.withValues(alpha: 0.9),
                                shape: const CircleBorder(),
                                elevation: 2,
                                shadowColor: Colors.black26,
                                child: InkWell(
                                  customBorder: const CircleBorder(),
                                  onTap: () {
                                    store.toggleSaved(p.id);
                                    HapticFeedback.lightImpact();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(7),
                                    child: AnimatedSwitcher(
                                      duration: Harvest.microMotion,
                                      child: Icon(
                                        saved
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        key: ValueKey(saved),
                                        size: 18,
                                        color: saved
                                            ? Harvest.tomato
                                            : Harvest.forest,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (p.stock == 0)
                          const Positioned(
                            left: 6,
                            bottom: 6,
                            child: StatusBadge(
                              'Sold out',
                              warning: true,
                              icon: Icons.remove_circle_outline,
                            ),
                          )
                        else if (p.stock < 5)
                          Positioned(
                            left: 6,
                            bottom: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Harvest.honey,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Low stock (${p.stock})',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Harvest.darkSoil,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      p.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.farm(p.farmId).name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: Harvest.colors(context).muted,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Text.rich(
                            TextSpan(
                              children: [
                                TextSpan(
                                  text: money(p.price),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    color: Harvest.colors(context).ink,
                                  ),
                                ),
                                TextSpan(
                                  text: ' /${p.unit}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Harvest.colors(context).muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (store.role != UserRole.customer)
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 14,
                            color: Harvest.colors(context).muted,
                          )
                        else
                          Material(
                            color: p.stock == 0
                                ? Harvest.colors(context).border
                                : Harvest.forest,
                            borderRadius: BorderRadius.circular(10),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(10),
                              onTap: p.stock == 0
                                  ? null
                                  : () {
                                      final error = store.setQuantity(
                                        p.id,
                                        (store.basket[p.id] ?? 0) + 1,
                                      );
                                      notice(
                                        context,
                                        error ?? '${p.name} added to basket',
                                      );
                                      if (error == null) {
                                        HapticFeedback.lightImpact();
                                      }
                                    },
                              child: const Padding(
                                padding: EdgeInsets.all(7),
                                child: Icon(
                                  Icons.add,
                                  size: 17,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.products, required this.onOpen});
  final List<Product> products;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final scale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final columns = constraints.maxWidth > 600 ? 3 : 2;
      final ratio = (0.64 / (scale > 1.0 ? (scale * 0.95) : 1)).clamp(
        0.42,
        0.70,
      );
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          crossAxisSpacing: 14,
          mainAxisSpacing: 16,
          childAspectRatio: ratio,
        ),
        itemBuilder: (context, index) => ProductCard(
          product: products[index],
          onOpen: () => onOpen(products[index]),
        ),
      );
    },
  );
}

class FarmerCard extends StatelessWidget {
  const FarmerCard({super.key, required this.farm, required this.onTap});

  final Farm farm;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Container(
    width: 250,
    margin: const EdgeInsets.only(right: 14),
    decoration: BoxDecoration(
      color: Harvest.colors(context).surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Harvest.colors(context).border),
      boxShadow: Harvest.cardShadow,
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Photo(farm.image, width: 48, height: 48, radius: 14),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farm.location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Harvest.colors(context).muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              farm.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: Harvest.colors(context).muted,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Harvest.colors(context).paleLeaf,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    farm.market,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Harvest.colors(context).green,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'View farm',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Harvest.colors(context).green,
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: Harvest.colors(context).green,
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class MenuRow extends StatelessWidget {
  const MenuRow({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.onTap,
    this.trailing,
    this.isDanger = false,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool isDanger;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: isDanger
              ? const Color(0xFFFBECE7)
              : Harvest.colors(context).paleLeaf,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDanger ? Harvest.danger : Harvest.forest,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: isDanger ? Harvest.danger : Harvest.colors(context).ink,
        ),
      ),
      subtitle: subtitle == null
          ? null
          : Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: Harvest.colors(context).muted,
              ),
            ),
      trailing:
          trailing ??
          Icon(
            Icons.arrow_forward_ios,
            size: 13,
            color: Harvest.colors(context).muted,
          ),
      onTap: onTap,
    ),
  );
}

class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.dark = false,
    this.icon,
    this.subtitle,
  });

  final String label, value;
  final bool dark;
  final IconData? icon;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: dark ? Harvest.forest : Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: dark ? Colors.transparent : Harvest.colors(context).border,
        width: 1,
      ),
      boxShadow: Harvest.cardShadow,
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: dark
                      ? Harvest.colors(context).softSage
                      : Harvest.colors(context).muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (icon != null)
              Icon(icon, size: 18, color: dark ? Harvest.honey : Harvest.green),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: Harvest.editorial(
            28,
            color: dark ? Colors.white : Harvest.colors(context).ink,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 11,
              color: dark ? Colors.white70 : Harvest.colors(context).muted,
            ),
          ),
        ],
      ],
    ),
  );
}

class SkeletonBox extends StatelessWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 12});

  final double? width, height;
  final double radius;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: Harvest.colors(context).canvas,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

/// Circular nav / action button matching the reference design top-bar buttons
class CircularNavButton extends StatelessWidget {
  const CircularNavButton({
    super.key,
    required this.icon,
    this.onTap,
    this.onPressed,
    this.showBadge = false,
    this.hasBadge = false,
    this.tooltip,
    this.badgeColor,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final VoidCallback? onPressed;
  final bool showBadge;
  final bool hasBadge;
  final String? tooltip;
  final Color? badgeColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: tooltip ?? '',
    child: Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 0,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap ?? onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Harvest.colors(context).border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: iconColor ?? Harvest.colors(context).ink,
              ),
              if (showBadge || hasBadge)
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: badgeColor ?? Harvest.tomato,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Weather & Farm Climate Card matching Reference Image 1 (Screen 1 & 3)
class GrowthAreaChart extends StatelessWidget {
  const GrowthAreaChart({
    super.key,
    this.title = 'Order value',
    this.period = 'Last 7 days',
    this.onPeriodChange,
  });
  final String title, period;
  final VoidCallback? onPeriodChange;
  @override
  Widget build(BuildContext context) {
    final orders = HarvestScope.of(context).visibleOrders;
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final values = List<int>.filled(7, 0);
    for (final o in orders) {
      final day = o.date.toUtc().difference(start).inDays;
      if (!o.date.toUtc().isBefore(start) && day >= 0 && day < 7) {
        values[day] += o.total;
      }
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Harvest.colors(context).surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Harvest.colors(context).border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Loaded orders - last 7 days',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          AnimatedHarvestChart(
            values: values.map((v) => v.toDouble()).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Simulated value - oldest to newest',
            style: TextStyle(
              fontSize: 11,
              color: Harvest.colors(context).muted,
            ),
          ),
        ],
      ),
    );
  }
}

class DataStatusBar extends StatelessWidget {
  const DataStatusBar({super.key});
  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (store.loading || store.busy) const LinearProgressIndicator(),
        if (store.error != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    store.error!,
                    style: const TextStyle(color: Harvest.danger, fontSize: 12),
                  ),
                ),
                TextButton.icon(
                  onPressed: store.loading ? null : store.refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        if (store.hasMore)
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton.icon(
                onPressed: store.loading ? null : store.loadMore,
                icon: const Icon(Icons.expand_more_rounded, size: 18),
                label: const Text('Load more records'),
              ),
            ),
          ),
      ],
    );
  }
}
