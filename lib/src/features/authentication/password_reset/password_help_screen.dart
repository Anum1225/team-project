part of '../authentication.dart';

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
  String _submittedEmail = '';
  Timer? _resendTimer;
  int _resendSeconds = 0;
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
    _resendTimer?.cancel();
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
                              color: const Color(0xFFF59E0B)
                                  .withValues(alpha: 0.25),
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
                            label: _resendSeconds > 0
                                ? 'Request again in ${_resendSeconds}s'
                                : 'Request reset link',
                            icon: Icons.send_rounded,
                            onPressed:
                                HarvestScope.of(context).busy ||
                                    _resendSeconds > 0
                                ? null
                                : () async {
                                    if (!form.currentState!.validate()) return;
                                    final recipient = email.text.trim();
                                    final result = await HarvestScope.of(
                                      context,
                                    ).resetPassword(recipient);
                                    if (!context.mounted) return;
                                    if (result != null) {
                                      notice(context, result, isError: true);
                                    } else {
                                      setState(() {
                                        submitted = true;
                                        _submittedEmail = recipient;
                                        _resendSeconds = 60;
                                      });
                                      _resendTimer?.cancel();
                                      _resendTimer = Timer.periodic(
                                        const Duration(seconds: 1),
                                        (timer) {
                                          if (!mounted) {
                                            timer.cancel();
                                            return;
                                          }
                                          setState(() => _resendSeconds--);
                                          if (_resendSeconds == 0) {
                                            timer.cancel();
                                          }
                                        },
                                      );
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
                                          'If an account exists for $_submittedEmail, a password reset link is on its way. You can return to Sign In.',
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
