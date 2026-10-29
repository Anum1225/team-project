import 'package:flutter/material.dart';

/// Presentation overrides applied only to authenticated customer routes.
ThemeData customerTheme(ThemeData base) => base.copyWith(
  appBarTheme: base.appBarTheme.copyWith(
    centerTitle: false,
    scrolledUnderElevation: 0,
    titleSpacing: 20,
    titleTextStyle: base.textTheme.titleLarge?.copyWith(
      fontFamily: 'Manrope',
      fontSize: 20,
      fontWeight: FontWeight.w800,
      color: base.colorScheme.onSurface,
    ),
  ),
  inputDecorationTheme: base.inputDecorationTheme.copyWith(
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
    floatingLabelBehavior: FloatingLabelBehavior.auto,
  ),
  bottomSheetTheme: base.bottomSheetTheme.copyWith(
    backgroundColor: base.colorScheme.surface,
    surfaceTintColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
  ),
);

class CustomerEmptyState extends StatelessWidget {
  const CustomerEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
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
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: .08),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(
              icon,
              size: 36,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              height: 1.5,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          if (action != null) ...[const SizedBox(height: 18), action!],
        ],
      ),
    ),
  );
}
