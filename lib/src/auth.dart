import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'components.dart';
import 'models.dart';
import 'theme.dart';
import 'theme_reveal.dart';
import 'location_picker.dart';

/// Awards-level modern authentication experience for HarvestHub with liquid
/// motion, ambient organic backdrop, frosted glass surfaces, and role-adaptive styling.
class _PasswordEye extends StatelessWidget {
  const _PasswordEye({required this.open});
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

class _AuthPhotoPanel extends StatelessWidget {
  const _AuthPhotoPanel({required this.role});
  final UserRole role;
  @override
  Widget build(BuildContext context) {
    final colors = Harvest.colors(context);
    final farmer = role == UserRole.farmer;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: Container(
        key: ValueKey(role),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colors.paleLeaf,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(36),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(36),
              ),
              child: Image.asset(
                farmer
                    ? 'assets/images/farmer_holding_crate.jpg'
                    : role == UserRole.admin
                    ? 'assets/images/farm_hero_banner.jpg'
                    : 'assets/images/farm_produce_crate.jpg',
                width: 92,
                height: 96,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farmer
                        ? 'From your farm,\nto their table.'
                        : role == UserRole.admin
                        ? 'Your marketplace.\nIn good hands.'
                        : 'Good food.\nCloser to home.',
                    style: TextStyle(
                      fontSize: 17,
                      height: 1.25,
                      fontWeight: FontWeight.w700,
                      color: colors.ink,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    farmer
                        ? 'Your growing community awaits.'
                        : role == UserRole.admin
                        ? 'Manage the HarvestHub community.'
                        : 'Welcome to your local harvest.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: colors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }
}

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role});

  final UserRole role;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final confirmPassword = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();
  String? selectedCoordinates;

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  late final List<Animation<double>> _rises = [
    const Interval(0.00, 0.40, curve: Curves.easeOutCubic),
    const Interval(0.12, 0.52, curve: Curves.easeOutCubic),
    const Interval(0.24, 0.64, curve: Curves.easeOutCubic),
    const Interval(0.36, 0.78, curve: Curves.easeOutCubic),
    const Interval(0.48, 0.92, curve: Curves.easeOutCubic),
  ].map((i) => CurvedAnimation(parent: _entrance, curve: i)).toList();

  late UserRole currentRole = widget.role == UserRole.farmer
      ? UserRole.farmer
      : UserRole.customer;
  bool register = false;
  bool rememberMe = true;
  bool hidden = true;
  bool confirmHidden = true;
  bool busy = false;
  int step = 0;
  String? error;
  bool _motionStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_motionStarted) return;
    _motionStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
    } else {
      _entrance.forward();
    }
  }

  @override
  void dispose() {
    for (final c in [email, password, confirmPassword, name, phone, address]) {
      c.dispose();
    }
    _entrance.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (register && step == 0) {
      setState(() => step = 1);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final store = HarvestScope.of(context);
    final result = register
        ? await store.register(
            email.text,
            password.text,
            name.text,
            phone.text,
            address.text,
            currentRole,
          )
        : await store.signIn(email.text, password.text);
    if (!mounted) return;
    setState(() {
      busy = false;
      error = result;
    });
    if (result == null) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  Widget _rise(int slot, Widget child) => AnimatedBuilder(
    animation: _rises[slot],
    builder: (context, _) => Opacity(
      opacity: _rises[slot].value,
      child: Transform.translate(
        offset: Offset(0, 20 * (1 - _rises[slot].value)),
        child: child,
      ),
    ),
  );

  Color get _roleAccentColor => switch (currentRole) {
    UserRole.customer => const Color(0xFFF59E0B),
    UserRole.farmer => const Color(0xFF10B981),
    UserRole.admin => const Color(0xFF8B5CF6),
  };

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF071F15) : Colors.white,
      body: Stack(
        children: [
          // Dynamic organic aura & particle backdrop
          AuthBackdrop(drift: _entrance, accentColor: _roleAccentColor),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    // Top navigation bar: Frosted back button + theme toggle + role pill
                    _rise(
                      0,
                      Row(
                        children: [
                          if (Navigator.of(context).canPop())
                            _GlassButton(
                              tooltip: 'Back',
                              icon: Icons.arrow_back_rounded,
                              onTap: () => Navigator.maybePop(context),
                            ),
                          const Spacer(),
                          Builder(
                            builder: (ctx) {
                              final isDarkTheme =
                                  Theme.of(ctx).brightness == Brightness.dark;
                              return _GlassButton(
                                tooltip: isDarkTheme
                                    ? 'Switch to light mode'
                                    : 'Switch to dark mode',
                                icon: isDarkTheme
                                    ? Icons.light_mode_rounded
                                    : Icons.dark_mode_rounded,
                                onTap: () => ThemeReveal.toggle(ctx),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Brand Emblem with glowing aura halo
                    _rise(
                      0,
                      Center(
                        child: AuthBackdrop.pulse(
                          reduced: reduced,
                          child: Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF10B981,
                              ).withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(
                                  0xFF10B981,
                                ).withValues(alpha: 0.40),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF10B981,
                                  ).withValues(alpha: 0.28),
                                  blurRadius: 28,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(child: SeedMark(size: 42)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Editorial Title & Tagline matching reference Image 1
                    _rise(
                      1,
                      Column(
                        children: [
                          RichText(
                            textAlign: TextAlign.center,
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 29,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Harvest',
                                  style: TextStyle(color: Color(0xFF087235)),
                                ),
                                TextSpan(
                                  text: 'Hub',
                                  style: TextStyle(color: Color(0xFFF27720)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Fresh from Farms, Good for You',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF287246),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            register
                                ? 'Create your ${currentRole.label.toLowerCase()} account'
                                : 'Welcome back',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Harvest.colors(context).ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (!register)
                      _rise(2, const _AuthPhotoPanel(role: UserRole.customer)),
                    const SizedBox(height: 18),

                    // Main Frosted Glass Form Card
                    _rise(
                      3,
                      Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Harvest.colors(context).surface,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: Harvest.colors(context).border,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.07),
                              blurRadius: 18,
                              offset: const Offset(0, 7),
                            ),
                            BoxShadow(
                              color: _roleAccentColor.withValues(alpha: 0.08),
                              blurRadius: 24,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (register) ...[
                              Text(
                                'How will you use HarvestHub?',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Harvest.colors(context).ink,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Shop fresh harvests or grow your farm business.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                  color: Harvest.colors(context).muted,
                                ),
                              ),
                              const SizedBox(height: 14),
                            ],
                            if (register)
                              _RoleSwitcher(
                                role: currentRole,
                                busy: busy,
                                onChanged: (r) => setState(() {
                                  currentRole = r;
                                  step = 0;
                                  error = null;
                                }),
                              ),
                            const SizedBox(height: 14),
                            // Registration Step Indicator
                            if (register) ...[
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Harvest.colors(
                                        context,
                                      ).green.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'STEP ${step + 1} OF 2',
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: Harvest.colors(context).green,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    step == 0
                                        ? 'Personal details'
                                        : 'Account credentials',
                                    style: TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Harvest.colors(context).muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  for (var s = 0; s < 2; s++) ...[
                                    if (s > 0) const SizedBox(width: 8),
                                    Expanded(
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 300,
                                        ),
                                        curve: Curves.easeOutCubic,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: step >= s
                                              ? Harvest.colors(context).green
                                              : Harvest.colors(
                                                  context,
                                                ).border.withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: step >= s
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        Harvest.colors(
                                                          context,
                                                        ).green.withValues(
                                                          alpha: 0.35,
                                                        ),
                                                    blurRadius: 6,
                                                  ),
                                                ]
                                              : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 22),
                            ],

                            // Form Fields with Sleek Modern Styling
                            Theme(
                              data: Theme.of(context).copyWith(
                                inputDecorationTheme: InputDecorationTheme(
                                  filled: true,
                                  fillColor:
                                      Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? const Color(0xFF18261E)
                                      : const Color(0xFFF7FAF8),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 16,
                                  ),
                                  labelStyle: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: Harvest.colors(context).muted,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  hintStyle: TextStyle(
                                    fontFamily: 'Manrope',
                                    color: Harvest.colors(context).muted,
                                    fontSize: 14,
                                  ),
                                  prefixIconColor: Harvest.colors(
                                    context,
                                  ).muted,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Harvest.colors(context).border,
                                      width: 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Harvest.colors(context).border,
                                      width: 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: Harvest.colors(context).green,
                                      width: 1.8,
                                    ),
                                  ),
                                  errorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Harvest.danger,
                                      width: 1.2,
                                    ),
                                  ),
                                  focusedErrorBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(
                                      color: Harvest.danger,
                                      width: 1.8,
                                    ),
                                  ),
                                ),
                              ),
                              child: Form(
                                key: form,
                                child: AutofillGroup(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      if (register && step == 0) ...[
                                        HarvestField(
                                          controller: name,
                                          label: 'Full name',
                                          prefixIcon: Icons.badge_outlined,
                                          autofillHints: const [
                                            AutofillHints.name,
                                          ],
                                          validator: nameValidator,
                                        ),
                                        const SizedBox(height: 14),
                                        HarvestField(
                                          controller: phone,
                                          label: 'Mobile phone',
                                          prefixIcon:
                                              Icons.phone_iphone_rounded,
                                          keyboard: TextInputType.phone,
                                          autofillHints: const [
                                            AutofillHints.telephoneNumber,
                                          ],
                                          validator: phoneValidator,
                                        ),
                                        const SizedBox(height: 14),
                                        HarvestField(
                                          controller: address,
                                          suffix: LocationPickerButton(
                                            onSelected: (value) {
                                              var typed = address.text.trim();
                                              final previous = selectedCoordinates;
                                              if (previous != null) {
                                                if (typed == previous) {
                                                  typed = '';
                                                } else if (typed.endsWith(' ($previous)')) {
                                                  typed = typed.substring(0, typed.length - previous.length - 3);
                                                }
                                              }
                                              address.text = typed.isEmpty ? value : '$typed ($value)';
                                              selectedCoordinates = value;
                                            },
                                          ),
                                          label: currentRole == UserRole.farmer
                                              ? 'Farm location & farm stand address'
                                              : 'Delivery street address',
                                          prefixIcon:
                                              Icons.location_on_outlined,
                                          lines: 2,
                                          validator: addressValidator,
                                        ),
                                      ] else ...[
                                        HarvestField(
                                          controller: email,
                                          label: 'Email address',
                                          prefixIcon:
                                              Icons.alternate_email_rounded,
                                          keyboard: TextInputType.emailAddress,
                                          autofillHints: const [
                                            AutofillHints.email,
                                          ],
                                          validator: emailValidator,
                                        ),
                                        const SizedBox(height: 14),
                                        TextFormField(
                                          controller: password,
                                          obscureText: hidden,
                                          onChanged: (v) {
                                            if (register) setState(() {});
                                          },
                                          autofillHints: register
                                              ? [AutofillHints.newPassword]
                                              : [AutofillHints.password],
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 15,
                                            color: Harvest.colors(context).ink,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: 'Password',
                                            prefixIcon: const Icon(
                                              Icons.lock_outline_rounded,
                                              size: 20,
                                            ),
                                            suffixIcon: IconButton(
                                              tooltip: hidden
                                                  ? 'Show password'
                                                  : 'Hide password',
                                              onPressed: () => setState(
                                                () => hidden = !hidden,
                                              ),
                                              icon: _PasswordEye(open: !hidden),
                                            ),
                                          ),
                                          validator: (v) => passwordValidator(
                                            v,
                                            isRegistration: register,
                                          ),
                                        ),
                                        if (register) ...[
                                          const SizedBox(height: 10),
                                          _PasswordStrengthMeter(
                                            password: password.text,
                                          ),
                                          const SizedBox(height: 10),
                                          _PasswordChecklist(
                                            password: password.text,
                                          ),
                                          const SizedBox(height: 14),
                                          TextFormField(
                                            controller: confirmPassword,
                                            obscureText: confirmHidden,
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontSize: 15,
                                              color: Harvest.colors(
                                                context,
                                              ).ink,
                                            ),
                                            decoration: InputDecoration(
                                              labelText: 'Confirm Password',
                                              prefixIcon: const Icon(
                                                Icons.lock_reset_rounded,
                                                size: 20,
                                              ),
                                              suffixIcon: IconButton(
                                                tooltip: confirmHidden
                                                    ? 'Show password'
                                                    : 'Hide password',
                                                onPressed: () => setState(
                                                  () => confirmHidden =
                                                      !confirmHidden,
                                                ),
                                                icon: _PasswordEye(
                                                  open: !confirmHidden,
                                                ),
                                              ),
                                            ),
                                            validator: (v) {
                                              if (v == null || v.isEmpty) {
                                                return 'Please confirm your password.';
                                              }
                                              if (v != password.text) {
                                                return 'Passwords do not match.';
                                              }
                                              return null;
                                            },
                                          ),
                                        ],
                                        if (!register) ...[
                                          const SizedBox(height: 10),
                                          Wrap(
                                            alignment:
                                                WrapAlignment.spaceBetween,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            spacing: 8,
                                            runSpacing: 4,
                                            children: [
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                onTap: () => setState(
                                                  () =>
                                                      rememberMe = !rememberMe,
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(
                                                      width: 20,
                                                      height: 20,
                                                      child: Checkbox(
                                                        value: rememberMe,
                                                        onChanged: (v) =>
                                                            setState(
                                                              () => rememberMe =
                                                                  v ?? true,
                                                            ),
                                                        activeColor:
                                                            const Color(
                                                              0xFF10B981,
                                                            ),
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                5,
                                                              ),
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      'Remember me',
                                                      style: TextStyle(
                                                        fontFamily: 'Manrope',
                                                        fontSize: 13,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                        color: Harvest.colors(
                                                          context,
                                                        ).muted,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              TextButton(
                                                onPressed: () => openPage(
                                                  context,
                                                  const PasswordHelpScreen(),
                                                ),
                                                style: TextButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 6,
                                                        vertical: 4,
                                                      ),
                                                ),
                                                child: const Text(
                                                  'Forgot Password?',
                                                  style: TextStyle(
                                                    fontFamily: 'Manrope',
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w700,
                                                    color: Color(0xFF10B981),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                      const SizedBox(height: 16),

                                      if (error != null) ...[
                                        InfoNote(error!, error: true),
                                        const SizedBox(height: 14),
                                      ],

                                      // Submit button
                                      HarvestButton(
                                        label: register
                                            ? (step == 0
                                                  ? 'Continue →'
                                                  : 'Create Account →')
                                            : 'Sign in',
                                        busy: busy,
                                        onPressed: submit,
                                      ),

                                      const SizedBox(height: 20),

                                      // Bottom Switcher: Don't have an account? Sign Up
                                      if (currentRole != UserRole.admin)
                                        Center(
                                          child: Wrap(
                                            alignment: WrapAlignment.center,
                                            crossAxisAlignment:
                                                WrapCrossAlignment.center,
                                            children: [
                                              Text(
                                                register
                                                    ? 'Already have an account? '
                                                    : "Don't have an account? ",
                                                style: TextStyle(
                                                  fontFamily: 'Manrope',
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: Harvest.colors(
                                                    context,
                                                  ).muted,
                                                ),
                                              ),
                                              InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                                onTap: () => setState(() {
                                                  register = !register;
                                                  step = 0;
                                                  error = null;
                                                  form.currentState?.reset();
                                                }),
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 4,
                                                        vertical: 2,
                                                      ),
                                                  child: Text(
                                                    register
                                                        ? 'Sign In'
                                                        : 'Sign Up',
                                                    style: const TextStyle(
                                                      fontFamily: 'Manrope',
                                                      fontSize: 13,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      color: Color(0xFF10B981),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                      if (register && step == 1) ...[
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: () =>
                                              setState(() => step = 0),
                                          icon: const Icon(
                                            Icons.arrow_back_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Back to personal details',
                                            style: TextStyle(
                                              fontFamily: 'Manrope',
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}

/// Organic animated atmosphere with drifting floating radiant orbs.
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

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? nameValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Full name is required.';
  }
  if (value.trim().length < 3) {
    return 'Full name must be at least 3 characters.';
  }
  if (!RegExp(r"^[a-zA-Z\s\-']+$").hasMatch(value.trim())) {
    return 'Name can only contain letters, spaces, and hyphens.';
  }
  return null;
}

String? phoneValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Mobile phone is required.';
  }
  final digits = value.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 10 || digits.length > 15) {
    return 'Enter a valid phone number (10–15 digits).';
  }
  return null;
}

String? addressValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Address is required.';
  }
  if (value.trim().length < 6) {
    return 'Please enter a complete address (at least 6 characters).';
  }
  return null;
}

String? emailValidator(String? value) {
  if (value == null || value.trim().isEmpty) {
    return 'Enter a valid email address.';
  }
  final clean = value.trim();
  final regex = RegExp(
    r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$",
  );
  if (!regex.hasMatch(clean)) {
    return 'Enter a valid email address.';
  }
  return null;
}

String? passwordValidator(String? value, {bool isRegistration = false}) {
  if (value == null || value.isEmpty) {
    return 'Password is required.';
  }
  if (value.length < 8) {
    return 'Password must be at least 8 characters.';
  }
  if (isRegistration) {
    if (!RegExp(r'[A-Z]').hasMatch(value) ||
        !RegExp(r'[a-z]').hasMatch(value)) {
      return 'Include both uppercase and lowercase letters.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Include at least one number (0–9).';
    }
  }
  return null;
}

int calculatePasswordStrength(String password) {
  if (password.isEmpty) return 0;
  int score = 0;
  if (password.length >= 8) score++;
  if (RegExp(r'[A-Z]').hasMatch(password) &&
      RegExp(r'[a-z]').hasMatch(password)) {
    score++;
  }
  if (RegExp(r'\d').hasMatch(password)) score++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
  return score;
}

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
class HarvestField extends StatelessWidget {
  const HarvestField({
    super.key,
    required this.controller,
    this.label = '',
    this.hint,
    this.prefixIcon,
    this.keyboard = TextInputType.text,
    this.obscure = false,
    this.suffix,
    this.validator,
    this.lines = 1,
    this.autofillHints,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? prefixIcon;
  final TextInputType keyboard;
  final bool obscure;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;
  final int lines;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: lines > 1 && keyboard == TextInputType.text
        ? TextInputType.multiline
        : keyboard,
    obscureText: obscure,
    maxLines: lines,
    validator: validator ?? requiredValidator,
    autofillHints: autofillHints,
    onChanged: onChanged,
    style: TextStyle(
      fontFamily: 'Manrope',
      fontSize: 15,
      color: Harvest.colors(context).ink,
    ),
    decoration: InputDecoration(
      labelText: label.isNotEmpty ? label : null,
      hintText: hint,
      alignLabelWithHint: lines > 1,
      prefixIcon: prefixIcon == null
          ? null
          : Icon(prefixIcon, size: 20, color: Harvest.colors(context).muted),
      suffixIcon: suffix,
    ),
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
  );
}

/// Sleek Password Reset & Account Recovery Screen
class PasswordHelpScreen extends StatefulWidget {
  const PasswordHelpScreen({super.key});

  @override
  State<PasswordHelpScreen> createState() => _PasswordHelpScreenState();
}

class _PasswordHelpScreenState extends State<PasswordHelpScreen>
    with SingleTickerProviderStateMixin {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool submitted = false;
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !MediaQuery.disableAnimationsOf(context)) {
        _entrance.forward();
      } else if (mounted) {
        _entrance.value = 1;
      }
    });
  }

  @override
  void dispose() {
    email.dispose();
    _entrance.dispose();
    super.dispose();
  }

  Widget _rise(double begin, Widget child) {
    final curve = CurvedAnimation(
      parent: _entrance,
      curve: Interval(begin, 1.0, curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curve,
      builder: (context, _) => Opacity(
        opacity: curve.value,
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - curve.value)),
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Harvest.colors(context).canvas,
    body: Stack(
      children: [
        AuthBackdrop(drift: _entrance, accentColor: const Color(0xFFF59E0B)),
        SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                children: [
                  _rise(
                    0,
                    Row(
                      children: [
                        _GlassButton(
                          tooltip: 'Back',
                          icon: Icons.arrow_back_rounded,
                          onTap: () => Navigator.maybePop(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _rise(
                    0.1,
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.22),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(
                                0xFFF59E0B,
                              ).withValues(alpha: 0.25),
                              blurRadius: 28,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.lock_reset_rounded,
                            size: 32,
                            color: Color(0xFF267545),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _rise(
                    0.2,
                    const Text(
                      'ACCOUNT RECOVERY',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.6,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _rise(
                    0.2,
                    Text(
                      'Let’s get you\nback in.',
                      style: Harvest.editorial(
                        42,
                        color: Harvest.colors(context).ink,
                        height: 1.08,
                        weight: FontWeight.w400,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _rise(
                    0.3,
                    Text(
                      'Enter the email address for your HarvestHub account and we’ll send a secure password reset link.',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        color: Harvest.colors(context).muted,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _rise(
                    0.4,
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Harvest.colors(context).surface,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                          color: Harvest.colors(context).border,
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.07),
                            blurRadius: 36,
                            offset: const Offset(0, 16),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Form(
                            key: form,
                            child: HarvestField(
                              controller: email,
                              label: 'Email address',
                              prefixIcon: Icons.alternate_email_rounded,
                              keyboard: TextInputType.emailAddress,
                              validator: emailValidator,
                            ),
                          ),
                          const SizedBox(height: 18),
                          HarvestButton(
                            label: 'Request reset link',
                            icon: Icons.send_rounded,
                            onPressed: HarvestScope.of(context).busy
                                ? null
                                : () async {
                                    if (!form.currentState!.validate()) return;
                                    final result = await HarvestScope.of(
                                      context,
                                    ).resetPassword(email.text);
                                    if (!context.mounted) return;
                                    if (result != null) {
                                      notice(context, result, isError: true);
                                    } else {
                                      setState(() => submitted = true);
                                    }
                                  },
                          ),
                          if (submitted) ...[
                            const SizedBox(height: 20),
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEDF8F1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFCDE8D6),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF16A34A),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Recovery request sent',
                                          style: TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0C3524),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'If an account exists for ${email.text}, a password reset link is on its way. You can return to Sign In.',
                                          style: const TextStyle(
                                            fontFamily: 'Manrope',
                                            fontSize: 13,
                                            color: Color(0xFF425E4D),
                                            height: 1.45,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
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
  );
}
