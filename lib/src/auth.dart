import 'package:flutter/material.dart';

import 'components.dart';
import 'models.dart';
import 'theme.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.role, required this.onPreview});

  final UserRole role;
  final ValueChanged<UserRole> onPreview;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController();
  final password = TextEditingController();
  final name = TextEditingController();
  final phone = TextEditingController();
  final address = TextEditingController();

  late UserRole currentRole = widget.role;
  bool register = false;
  bool hidden = true;
  bool busy = false;
  int step = 0;
  String? error;

  @override
  void dispose() {
    for (final c in [email, password, name, phone, address]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    if (register && currentRole != UserRole.admin && step == 0) {
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
        : await store.signIn(email.text, password.text, currentRole);
    if (!mounted) return;
    setState(() {
      busy = false;
      error = result;
    });
    if (result == null) Navigator.of(context).popUntil((r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: currentRole.label,
    backgroundColor: Harvest.canvas,
    child: ListView(
      padding: EdgeInsets.zero,
      children: [
        // Top Brand Hero Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 30),
          decoration: const BoxDecoration(
            gradient: Harvest.heroGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            boxShadow: [
              BoxShadow(
                color: Color(0x1F0C3524),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const SeedMark(size: 32),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HARVESTHUB',
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                      Text(
                        '${currentRole.label} Portal',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Headline & Subtitle
              Text(
                register ? 'Good things\nstart here.' : 'Welcome\nback.',
                style: Harvest.editorial(
                  38,
                  color: const Color(0xFFFFFBEB),
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                register
                    ? 'A little about you, then you’re ready to grow.'
                    : 'Fresh finds are waiting.',
                style: const TextStyle(
                  color: Color(0xFFCDE3D5),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Main Card Container
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            children: [
              // Segmented Role Switcher Chips
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Harvest.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x060C2D1F),
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    for (final r in UserRole.values)
                      Expanded(
                        child: GestureDetector(
                          onTap: busy
                              ? null
                              : () => setState(() {
                                  currentRole = r;
                                  register = false;
                                  step = 0;
                                  error = null;
                                }),
                          child: AnimatedContainer(
                            duration: Harvest.motion,
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            decoration: BoxDecoration(
                              color: currentRole == r
                                  ? Harvest.forest
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              switch (r) {
                                UserRole.customer => '🛒 Shopper',
                                UserRole.farmer => '🌾 Farmer',
                                UserRole.admin => '🛡️ Admin',
                              },
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: currentRole == r
                                    ? FontWeight.w700
                                    : FontWeight.w600,
                                color: currentRole == r
                                    ? Colors.white
                                    : Harvest.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Segmented Sign In / Register Tab Toggle
              if (currentRole != UserRole.admin) ...[
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Harvest.sage,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            register = false;
                            step = 0;
                            error = null;
                            form.currentState?.reset();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: !register
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: !register
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x0A0C2D1F),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Sign In',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: !register
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: !register
                                    ? Harvest.forest
                                    : Harvest.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            register = true;
                            step = 0;
                            error = null;
                            form.currentState?.reset();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: register
                                  ? Colors.white
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(999),
                              boxShadow: register
                                  ? const [
                                      BoxShadow(
                                        color: Color(0x0A0C2D1F),
                                        blurRadius: 8,
                                        offset: Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Text(
                              'Create Account',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: register
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                                color: register
                                    ? Harvest.forest
                                    : Harvest.muted,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Multi-step Registration Progress Indicator
              if (register) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step 0${step + 1} of 02',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Harvest.forest,
                      ),
                    ),
                    Text(
                      step == 0 ? 'Personal Details' : 'Account Security',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Harvest.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (step + 1) / 2,
                    minHeight: 5,
                    backgroundColor: Harvest.sage,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Harvest.freshLeaf,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Main Form Container
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Harvest.border, width: 1.2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x080C2D1F),
                      blurRadius: 18,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Form(
                  key: form,
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (register && step == 0) ...[
                          HarvestField(
                            controller: name,
                            label: 'Full name',
                            prefixIcon: Icons.badge_outlined,
                            autofillHints: const [AutofillHints.name],
                          ),
                          const SizedBox(height: 16),
                          HarvestField(
                            controller: phone,
                            label: 'Mobile phone',
                            prefixIcon: Icons.phone_iphone_rounded,
                            keyboard: TextInputType.phone,
                            validator: (v) =>
                                v == null ||
                                    v.replaceAll(RegExp(r'\D'), '').length < 7
                                ? 'Enter a valid phone number.'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          HarvestField(
                            controller: address,
                            label: currentRole == UserRole.farmer
                                ? 'Farm location & address'
                                : 'Delivery address',
                            prefixIcon: Icons.location_on_outlined,
                            lines: 2,
                          ),
                        ] else ...[
                          HarvestField(
                            controller: email,
                            label: 'Email address',
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboard: TextInputType.emailAddress,
                            autofillHints: const [AutofillHints.email],
                            validator: emailValidator,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: password,
                            obscureText: hidden,
                            autofillHints: register
                                ? const [AutofillHints.newPassword]
                                : const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(
                                Icons.lock_outline_rounded,
                                size: 20,
                                color: Harvest.muted,
                              ),
                              suffixIcon: IconButton(
                                tooltip: hidden
                                    ? 'Show password'
                                    : 'Hide password',
                                onPressed: () =>
                                    setState(() => hidden = !hidden),
                                icon: Icon(
                                  hidden
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Harvest.muted,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.length < 8
                                ? 'Use at least 8 characters.'
                                : null,
                          ),
                          if (!register)
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => openPage(
                                  context,
                                  const PasswordHelpScreen(),
                                ),
                                child: const Text(
                                  'Forgot password?',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Harvest.forest,
                                  ),
                                ),
                              ),
                            ),
                        ],
                        const SizedBox(height: 18),

                        if (error != null) ...[
                          InfoNote(error!, error: true),
                          const SizedBox(height: 16),
                        ],

                        // Main Submit Action Button
                        HarvestButton(
                          label: register
                              ? (step == 0 ? 'Continue' : 'Create account')
                              : 'Sign in',
                          busy: busy,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: submit,
                        ),

                        if (register && step == 1) ...[
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: () => setState(() => step = 0),
                            child: const Text('Back to personal details'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ],
    ),
  );
}

String? requiredValidator(String? value) =>
    value == null || value.trim().isEmpty ? 'This field is required.' : null;

String? emailValidator(String? value) =>
    value == null ||
        !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(value.trim())
    ? 'Enter a valid email address.'
    : null;

class HarvestField extends StatelessWidget {
  const HarvestField({
    super.key,
    required this.controller,
    required this.label,
    this.keyboard,
    this.validator,
    this.lines = 1,
    this.autofillHints,
    this.helper,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String label;
  final TextInputType? keyboard;
  final String? Function(String?)? validator;
  final int lines;
  final Iterable<String>? autofillHints;
  final String? helper;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: keyboard,
    maxLines: lines,
    autofillHints: autofillHints,
    validator: validator ?? requiredValidator,
    decoration: InputDecoration(
      labelText: label,
      helperText: helper,
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, size: 20, color: Harvest.muted)
          : null,
    ),
    textInputAction: lines > 1 ? TextInputAction.newline : TextInputAction.next,
  );
}

class PasswordHelpScreen extends StatefulWidget {
  const PasswordHelpScreen({super.key});

  @override
  State<PasswordHelpScreen> createState() => _PasswordHelpScreenState();
}

class _PasswordHelpScreenState extends State<PasswordHelpScreen> {
  final email = TextEditingController();
  final form = GlobalKey<FormState>();
  bool submitted = false;

  @override
  void dispose() {
    email.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Account recovery',
    child: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Harvest.sage,
            shape: BoxShape.circle,
            border: Border.all(color: Harvest.border),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_reset_rounded,
              size: 30,
              color: Harvest.forest,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const PageHeading(
          'Let’s get you\nback in.',
          subtitle: 'Enter the email address you use for HarvestHub.',
        ),
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
        const SizedBox(height: 24),
        HarvestButton(
          label: 'Request reset link',
          onPressed: HarvestScope.of(context).busy
              ? null
              : () async {
                  if (!form.currentState!.validate()) return;
                  final result = await HarvestScope.of(context)
                      .resetPassword(email.text);
                  if (!context.mounted) return;
                  if (result != null) {
                    notice(context, result, isError: true);
                  } else {
                    setState(() => submitted = true);
                  }
                },
        ),
        if (submitted) ...[
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFEDF8F1),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFCDE8D6)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF16A34A),
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recovery request sent',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0C3524),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'If an account exists for ${email.text}, a password reset email will arrive. You can return to Sign In.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF425E4D),
                          height: 1.4,
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
  );
}
