part of '../authentication.dart';

class AuthBackdrop extends StatelessWidget {
  const AuthBackdrop({super.key, this.drift, this.accentColor});

  final Animation<double>? drift;
  final Color? accentColor;

  static Widget pulse({required bool reduced, required Widget child}) => reduced
      ? child
      : TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.92, end: 1.05),
          duration: const Duration(milliseconds: 2400),
          curve: Curves.easeInOut,
          builder: (context, s, child) => Transform.scale(
            scale: s,
            child: Opacity(opacity: 0.88 + 0.12 * (1.05 - s), child: child),
          ),
          child: child,
        );

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent =
        accentColor ??
        (isDark ? const Color(0xFF10B981) : const Color(0xFF3D7A44));

    Widget blobs(double v) {
      final sway = math.sin(v * math.pi);
      final cosSway = math.cos(v * math.pi);
      return Stack(
        children: [
          // Top-right radiant aura
          Positioned(
            top: -90 + 20 * sway,
            right: -70 + 16 * cosSway,
            child: _Blob(size: 280, color: accent, alpha: isDark ? 0.22 : 0.12),
          ),
          // Middle-left emerald aura
          Positioned(
            top: 200 + 24 * cosSway,
            left: -110 + 18 * sway,
            child: _Blob(
              size: 320,
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF3D7A44),
              alpha: isDark ? 0.18 : 0.10,
            ),
          ),
          // Subtle warm amber accent orb
          Positioned(
            bottom: 40 + 18 * sway,
            right: -50 + 12 * cosSway,
            child: _Blob(
              size: 250,
              color: const Color(0xFFF59E0B),
              alpha: isDark ? 0.14 : 0.08,
            ),
          ),
          // Deep soil grounding glow
          Positioned(
            bottom: -80,
            left: 20,
            child: _Blob(
              size: 260,
              color: isDark ? const Color(0xFF0E4D34) : const Color(0xFFC7DBCB),
              alpha: isDark ? 0.35 : 0.15,
            ),
          ),
        ],
      );
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? const [
                    Color(0xFF04170F),
                    Color(0xFF08281C),
                    Color(0xFF0A3324),
                    Color(0xFF061A12),
                  ]
                : const [
                    Color(0xFFFAFBF8),
                    Color(0xFFF0F5F1),
                    Color(0xFFE9F1EC),
                    Color(0xFFF3F7F4),
                  ],
            stops: const [0.0, 0.35, 0.70, 1.0],
          ),
        ),
        child: drift == null
            ? blobs(0.5)
            : AnimatedBuilder(
                animation: drift!,
                builder: (context, _) => blobs(drift!.value),
              ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color, required this.alpha});

  final double size;
  final Color color;
  final double alpha;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(
        colors: [
          color.withValues(alpha: alpha),
          color.withValues(alpha: 0),
        ],
      ),
    ),
  );
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.icon, required this.onTap, this.tooltip});

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: isDark
          ? Colors.white.withValues(alpha: 0.08)
          : Colors.black.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Tooltip(
          message: tooltip ?? '',
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.18)
                    : Colors.black.withValues(alpha: 0.10),
              ),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFFE7F3EC) : const Color(0xFF16251C),
            ),
          ),
        ),
      ),
    );
  }
}

/// Interactive Segmented Role Selector with sliding glowing pill
class _RoleSwitcher extends StatelessWidget {
  const _RoleSwitcher({
    required this.role,
    required this.busy,
    required this.onChanged,
  });

  final UserRole role;
  final bool busy;
  final ValueChanged<UserRole> onChanged;

  static const _roles = [UserRole.customer, UserRole.farmer];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final inner = constraints.maxWidth - 8;
      final thumbWidth = inner / _roles.length;
      final idx = _roles.indexOf(role);
      final active = idx >= 0 ? idx : 0;

      final activeGradient = switch (role) {
        UserRole.customer => const LinearGradient(
          colors: [Color(0xFF16A34A), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        UserRole.farmer => const LinearGradient(
          colors: [Color(0xFF0E4D34), Color(0xFF166534)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        UserRole.admin => const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      };

      final activeShadowColor = switch (role) {
        UserRole.customer => const Color(0xFF22C55E).withValues(alpha: 0.40),
        UserRole.farmer => const Color(0xFF10B981).withValues(alpha: 0.40),
        UserRole.admin => const Color(0xFF6366F1).withValues(alpha: 0.40),
      };

      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF16251C)
              : const Color(0xFFF1F5F2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Harvest.colors(context).border),
        ),
        child: SizedBox(
          height: 48,
          child: Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                left: 4 + active * thumbWidth,
                top: 4,
                bottom: 4,
                width: thumbWidth - 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: activeGradient,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: activeShadowColor,
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  for (final r in _roles)
                    Expanded(
                      child: InkWell(
                        onTap: busy ? null : () => onChanged(r),
                        borderRadius: BorderRadius.circular(15),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                switch (r) {
                                  UserRole.customer => Icons.person_rounded,
                                  UserRole.farmer => Icons.eco_rounded,
                                  UserRole.admin => Icons.settings_rounded,
                                },
                                size: 15,
                                color: r == role
                                    ? Colors.white
                                    : Harvest.colors(context).muted,
                              ),
                              const SizedBox(width: 5),
                              Flexible(
                                child: Text(
                                  switch (r) {
                                    UserRole.customer => 'Customer',
                                    UserRole.farmer => 'Farmer',
                                    UserRole.admin => 'Admin',
                                  },
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'Manrope',
                                    fontSize: 11.5,
                                    fontWeight: r == role
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: r == role
                                        ? Colors.white
                                        : Harvest.colors(context).ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}
