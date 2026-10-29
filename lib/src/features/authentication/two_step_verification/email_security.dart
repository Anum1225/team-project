import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../common/data/trusted_backend.dart';

Future<bool> hasEmailSecurityProof(
  User user,
  Map<String, dynamic> profile,
) async {
  final claims = (await user.getIdTokenResult()).claims ?? {};
  return validEmailSecurityClaims(claims, profile);
}

bool validEmailSecurityClaims(
  Map<String, dynamic> claims,
  Map<String, dynamic> profile,
) {
  if (profile['email2faEnabled'] == false) return true;
  final firebase = claims['firebase'];
  return firebase is Map &&
      firebase['sign_in_provider'] == 'custom' &&
      claims['hh_email_2fa'] == true &&
      claims['hh_verified_email'] == profile['email'] &&
      claims['hh_security_version'] == (profile['securityVersion'] ?? 0);
}

String accountSecurityError(Object error) {
  if (error is FirebaseFunctionsException) {
    if (error.code == 'not-found' || error.code == 'unavailable') {
      return 'Email verification is temporarily unavailable. Please try again later.';
    }
    return error.message ?? 'Account verification could not finish.';
  }
  if (error is FirebaseAuthException) {
    return switch (error.code) {
      'wrong-password' ||
      'invalid-credential' => 'The current password is incorrect.',
      'weak-password' => 'Use a stronger password.',
      'too-many-requests' => 'Too many attempts. Please wait and try again.',
      'requires-recent-login' ||
      'user-token-expired' => 'Sign in again to continue.',
      _ =>
        'The account service is unavailable. Check your connection and retry.',
    };
  }
  if (error is StateError) return error.message;
  return 'Could not connect. Please try again.';
}

String? newPasswordError(String? value) {
  if (value == null || value.length < 8 || value.length > 128) {
    return 'Use 8–128 characters.';
  }
  if (!RegExp(r'[A-Z]').hasMatch(value) ||
      !RegExp(r'[a-z]').hasMatch(value) ||
      !RegExp(r'[0-9]').hasMatch(value)) {
    return 'Include uppercase, lowercase and a number.';
  }
  return null;
}

class EmailSecurityApi {
  static Completer<void>? _verification;
  static Future<void> waitForVerification() async {
    await _verification?.future;
  }

  static bool get enabled =>
      TrustedBackend.enabled ||
      const bool.fromEnvironment('EMAIL_CODE_BACKEND_ENABLED');
  static FirebaseFunctions get functions =>
      FirebaseFunctions.instanceFor(region: 'us-central1');
  static Future<Map<String, dynamic>> start(
    String purpose, {
    String? password,
    String? resendChallengeId,
  }) async {
    if (TrustedBackend.enabled) {
      return TrustedBackend.call('startEmailVerification', {
        'purpose': purpose,
        'password': password,
        'resendChallengeId': resendChallengeId,
      });
    }
    final result = await functions.httpsCallable('startEmailVerification').call(
      {
        'purpose': purpose,
        'password': password,
        'resendChallengeId': resendChallengeId,
        'apiKey': FirebaseAuth.instance.app.options.apiKey,
      },
    );
    return Map<String, dynamic>.from(result.data as Map);
  }

  static Future<void> verify(String id, String code) async {
    if (_verification != null) {
      throw StateError('Verification is already in progress.');
    }
    final operation = Completer<void>();
    _verification = operation;
    try {
      await _verifyAndSignIn(id, code);
    } finally {
      _verification = null;
      operation.complete();
    }
  }

  static Future<void> _verifyAndSignIn(String id, String code) async {
    if (TrustedBackend.enabled) {
      final result = await TrustedBackend.call('verifyEmailCode', {
        'challengeId': id,
        'code': code,
      });
      await FirebaseAuth.instance.signInWithCustomToken(
        result['token'] as String,
      );
      return;
    }
    final result = await functions.httpsCallable('verifyEmailCode').call({
      'challengeId': id,
      'code': code,
    });
    await FirebaseAuth.instance.signInWithCustomToken(
      result.data['token'] as String,
    );
  }

  static Future<void> changePassword(
    FirebaseAuth auth,
    String old,
    String password,
  ) async {
    final validation = newPasswordError(password);
    if (validation != null) throw StateError(validation);
    if (old == password) throw StateError('Choose a different password.');
    final user = auth.currentUser;
    if (user == null || user.email == null) {
      throw StateError('Sign in again to continue.');
    }
    final data = {
      'password': old,
      'newPassword': password,
      'apiKey': auth.app.options.apiKey,
    };
    if (TrustedBackend.enabled) {
      await TrustedBackend.call('changeVerifiedPassword', data);
    } else {
      await functions.httpsCallable('changeVerifiedPassword').call(data);
    }
    // Avoid leaving a stale local token/session after credential rotation.
    await auth.signOut();
  }

  static Future<void> changeEmail(
    FirebaseAuth auth,
    String password,
    String email,
  ) async {
    final user = auth.currentUser;
    final next = email.trim();
    if (user?.email == null) throw StateError('Sign in again to continue.');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(next)) {
      throw StateError('Enter a valid email address.');
    }
    if (next.toLowerCase() == user!.email!.toLowerCase()) {
      throw StateError('Enter a different email address.');
    }
    if (TrustedBackend.enabled) {
      await TrustedBackend.call('changeEmail', {
        'password': password,
        'email': next,
      });
    } else {
      throw StateError(
        'The verified account service must be available to change your email.',
      );
    }
  }
}

class EmailCodeScreen extends StatefulWidget {
  const EmailCodeScreen({
    super.key,
    required this.onCancel,
    this.purpose = 'login',
    this.challenge,
    this.startCode,
    this.verifyCode,
  });
  final Future<void> Function() onCancel;
  final String purpose;
  final Map<String, dynamic>? challenge;
  final Future<Map<String, dynamic>> Function(
    String purpose,
    String? resendChallengeId,
  )?
  startCode;
  final Future<void> Function(String id, String code)? verifyCode;
  @override
  State<EmailCodeScreen> createState() => _EmailCodeScreenState();
}

class _EmailCodeScreenState extends State<EmailCodeScreen> {
  final code = TextEditingController();
  Map<String, dynamic>? challenge;
  bool busy = false;
  String? error;
  Timer? timer;
  int _lastWaitSeconds = -1;
  int _lastExpirySeconds = -1;
  int _serverOffsetMs = 0;
  int get _now => DateTime.now().millisecondsSinceEpoch + _serverOffsetMs;
  int get expirySeconds {
    final expires = (challenge?['expiresAt'] as num?)?.toInt();
    if (expires == null) return 0;
    final remaining = expires - _now;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  void _setChallenge(Map<String, dynamic>? value) {
    challenge = value;
    final serverTime = (value?['serverTime'] as num?)?.toInt();
    _serverOffsetMs = serverTime == null
        ? 0
        : serverTime - DateTime.now().millisecondsSinceEpoch;
  }

  int get waitSeconds {
    final remaining =
        ((challenge?['resendAfter'] as num?)?.toInt() ?? 0) - _now;
    return remaining <= 0 ? 0 : (remaining / 1000).ceil();
  }

  @override
  void initState() {
    super.initState();
    _setChallenge(widget.challenge);
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted &&
          (waitSeconds != _lastWaitSeconds ||
              expirySeconds != _lastExpirySeconds)) {
        setState(() {
          _lastWaitSeconds = waitSeconds;
          _lastExpirySeconds = expirySeconds;
        });
      }
    });
    if (challenge == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => send());
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    code.dispose();
    super.dispose();
  }

  Future<void> send() async {
    if (busy || waitSeconds > 0) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final resendId = challenge?['challengeId'] as String?;
      final next = widget.startCode != null
          ? await widget.startCode!(widget.purpose, resendId)
          : await EmailSecurityApi.start(
              widget.purpose,
              resendChallengeId: resendId,
            );
      if (mounted) {
        setState(() {
          _setChallenge(next);
          code.clear();
        });
      }
    } catch (e) {
      if (mounted) setState(() => error = accountSecurityError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> verify() async {
    if (code.text.length != 6 || challenge == null || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await (widget.verifyCode ?? EmailSecurityApi.verify)(
        challenge!['challengeId'] as String,
        code.text,
      );
      if (mounted && widget.purpose != 'login') Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => error = accountSecurityError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: widget.purpose != 'login',
    child: Scaffold(
      appBar: AppBar(
        title: const Text('Email verification'),
        automaticallyImplyLeading: widget.purpose != 'login',
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: ListView(
            padding: const EdgeInsets.all(24),
            shrinkWrap: true,
            children: [
              Icon(
                Icons.mark_email_read_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                'Check your inbox',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 12),
              Text(
                challenge == null
                    ? 'Request a code to verify access to your account email.'
                    : 'Enter the six-digit code sent to ${challenge!['maskedEmail']}. Codes are valid for 30 minutes. If you resend, use the newest email.',
              ),
              if (challenge?['expiresAt'] is num)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    expirySeconds > 0
                        ? 'Code expires in ${expirySeconds ~/ 60}:${(expirySeconds % 60).toString().padLeft(2, '0')}'
                        : 'This code has expired. Request a new code below.',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextField(
                controller: code,
                enabled: !busy && challenge != null,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.oneTimeCode],
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(fontSize: 28, letterSpacing: 10),
                decoration: const InputDecoration(
                  labelText: 'Verification code',
                  counterText: '',
                ),
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => verify(),
              ),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: busy || code.text.length != 6 ? null : verify,
                child: Text(busy ? 'Please wait…' : 'Verify and continue'),
              ),
              TextButton(
                onPressed: busy || waitSeconds > 0 ? null : send,
                child: Text(
                  waitSeconds > 0
                      ? 'Resend in ${waitSeconds}s'
                      : challenge == null
                      ? 'Send code'
                      : 'Resend code',
                ),
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        await widget.onCancel();
                        if (context.mounted && widget.purpose != 'login') {
                          Navigator.pop(context);
                        }
                      },
                child: Text(
                  widget.purpose == 'login' ? 'Back to sign in' : 'Cancel',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Check spam or junk folders too. Never share this code.',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class EmailSecurityPanel extends StatefulWidget {
  const EmailSecurityPanel({
    super.key,
    this.profiles,
    this.startCode,
    this.verifyCode,
  });
  final Stream<Map<String, dynamic>>? profiles;
  final Future<Map<String, dynamic>> Function(String purpose, String password)?
  startCode;
  final Future<void> Function(String id, String code)? verifyCode;

  @override
  State<EmailSecurityPanel> createState() => _EmailSecurityPanelState();
}

class _EmailSecurityPanelState extends State<EmailSecurityPanel> {
  late final Stream<Map<String, dynamic>> profiles =
      widget.profiles ??
      FirebaseFirestore.instance
          .doc('users/${FirebaseAuth.instance.currentUser!.uid}')
          .snapshots()
          .map((doc) => doc.data() ?? {});
  bool busy = false;
  String? error;

  Future<void> change(bool enabled) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    var password = '';
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            enabled
                ? 'Enable two-step verification?'
                : 'Disable two-step verification?',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                enabled
                    ? 'Future sign-ins will require an email code. Confirm your password, then verify the code sent to your email.'
                    : 'Future sign-ins will use your password only. Confirm your password, then verify the code sent to your email.',
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (value) => password = value,
                obscureText: true,
                autofocus: true,
                decoration: const InputDecoration(
                  labelText: 'Current password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Send code'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      if (password.isEmpty) throw StateError('Enter your current password.');
      final purpose = enabled ? 'enroll' : 'disable';
      final challenge = widget.startCode != null
          ? await widget.startCode!(purpose, password)
          : await EmailSecurityApi.start(purpose, password: password);
      password = '';
      if (!mounted) return;
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => EmailCodeScreen(
            purpose: purpose,
            challenge: challenge,
            verifyCode: widget.verifyCode,
            onCancel: () async {},
          ),
        ),
      );
      if (changed == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              enabled
                  ? 'Two-step verification enabled.'
                  : 'Two-step verification disabled.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => error = accountSecurityError(e));
    } finally {
      password = '';
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => StreamBuilder<Map<String, dynamic>>(
    stream: profiles,
    builder: (context, snapshot) {
      final enabled = snapshot.data?['email2faEnabled'] != false;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Email two-step verification'),
                subtitle: Text(
                  !snapshot.hasData
                      ? 'Loading security settings…'
                      : enabled
                      ? 'Enabled · An email code is required when you sign in.'
                      : 'Disabled · Sign in with your password only.',
                ),
                value: snapshot.hasData && enabled,
                onChanged: busy || !snapshot.hasData || snapshot.hasError
                    ? null
                    : change,
              ),
              if (busy) const Text('Waiting for verification…'),
              if (error != null || snapshot.hasError)
                Text(
                  error ?? 'Could not load security settings. Please reopen this page.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      );
    },
  );
}
