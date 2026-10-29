part of '../authentication.dart';

class _PasswordStrengthMeter extends StatelessWidget {
  const _PasswordStrengthMeter({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final score = calculatePasswordStrength(password);
    if (password.isEmpty) return const SizedBox.shrink();

    final (label, color) = switch (score) {
      1 => ('Weak', const Color(0xFFC1442D)),
      2 => ('Fair', const Color(0xFFE8A93B)),
      3 => ('Good', const Color(0xFF5C8A3A)),
      4 => ('Strong', const Color(0xFF3D7A44)),
      _ => ('Very Weak', const Color(0xFFC1442D)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (int i = 0; i < 4; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < score
                        ? color
                        : Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF2B2620)
                        : const Color(0xFFE2DED3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PasswordChecklist extends StatelessWidget {
  const _PasswordChecklist({required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final hasLength = password.length >= 8;
    final hasCase =
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password);
    final hasDigit = RegExp(r'\d').hasMatch(password);
    final hasSpecial = RegExp(r'[^A-Za-z0-9]').hasMatch(password);

    Widget checkItem(String text, bool met) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          met
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 13,
          color: met ? const Color(0xFF3D7A44) : Harvest.colors(context).muted,
        ),
        const SizedBox(width: 5),
        Text(
          text,
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: met ? FontWeight.w600 : FontWeight.w500,
            color: met
                ? Harvest.colors(context).ink
                : Harvest.colors(context).muted,
          ),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Harvest.colors(context).paleLeaf.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Harvest.colors(context).border),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          checkItem('8+ chars', hasLength),
          checkItem('A-Z & a-z', hasCase),
          checkItem('Number (0-9)', hasDigit),
          checkItem('Symbol (!@#)', hasSpecial),
        ],
      ),
    );
  }
}

/// Reusable modern field matching the awards aesthetic across all screens
