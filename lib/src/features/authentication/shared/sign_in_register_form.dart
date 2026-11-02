part of '../authentication.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role, this.onDemo});

  final UserRole role;
  final VoidCallback? onDemo;

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
    form.currentState!.save();
    if (register && step == 0) {
      setState(() => step = 1);
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final store = HarvestScope.of(context);
    final wasRegistering = register;
    final result = wasRegistering
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
    if (result == null) {
      if (wasRegistering) {
        setState(() {
          register = false;
          step = 0;
          password.clear();
          confirmPassword.clear();
        });
        notice(
          context,
          'Account created. Wait for admin approval, then sign in.',
        );
        return;
      }
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
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
                              color: const Color(0xFF10B981)
                                  .withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: const Color(0xFF10B981)
                                    .withValues(alpha: 0.40),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF10B981)
                                      .withValues(alpha: 0.28),
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
                                      color: Harvest.colors(context).green
                                          .withValues(alpha: 0.12),
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
                                              : Harvest.colors(context).border
                                                    .withValues(alpha: 0.6),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          boxShadow: step >= s
                                              ? [
                                                  BoxShadow(
                                                    color:
                                                        Harvest.colors(context)
                                                            .green
                                                            .withValues(
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
                                  prefixIconColor: Harvest.colors(context)
                                      .muted,
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
                                        PhoneField(
                                          controller: phone,
                                          label: 'Mobile phone',
                                        ),
                                        const SizedBox(height: 14),
                                        HarvestField(
                                          controller: address,
                                          suffix: LocationPickerButton(
                                            onLocationSelected: (value) {
                                              address.text = value.address;
                                            },
                                          ),
                                          label: currentRole == UserRole.farmer
                                              ? 'Farm location & farm stand address'
                                              : 'Street address',
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
                                              icon: PasswordEye(open: !hidden),
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
                                              color: Harvest.colors(context)
                                                  .ink,
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
                                                icon: PasswordEye(
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
                                                  color: Harvest.colors(context)
                                                      .muted,
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

                                      if (widget.onDemo != null &&
                                          !register) ...[
                                        const SizedBox(height: 12),
                                        const Divider(),
                                        TextButton.icon(
                                          onPressed: busy
                                              ? null
                                              : widget.onDemo,
                                          icon: const Icon(
                                            Icons.explore_outlined,
                                          ),
                                          label: const Text(
                                            'Explore demo mode',
                                          ),
                                        ),
                                        const Text(
                                          'Browse products freely. Sign in when you’re ready to order.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
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
