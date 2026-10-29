part of '../../common/profile/profile.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});
  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final old = TextEditingController(),
      password = TextEditingController(),
      confirmation = TextEditingController();
  final form = GlobalKey<FormState>();
  bool submitted = false;
  bool showOld = false, showNew = false, showConfirmation = false;
  @override
  void dispose() {
    for (final c in [old, password, confirmation]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => HarvestPage(
    title: 'Password & security',
    child: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PageHeading(
            'Your account, protected.',
            subtitle: 'Use 8–128 characters with uppercase, lowercase and a number. You will sign in again after changing it.',
          ),
          TextFormField(
            controller: old,
            obscureText: !showOld,
            autofillHints: const [AutofillHints.password],
            decoration: InputDecoration(
              labelText: 'Current password',
              suffixIcon: IconButton(
                tooltip: showOld ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => showOld = !showOld),
                icon: PasswordEye(open: showOld),
              ),
            ),
            validator: requiredValidator,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: password,
            obscureText: !showNew,
            autofillHints: const [AutofillHints.newPassword],
            decoration: InputDecoration(
              labelText: 'New password',
              suffixIcon: IconButton(
                tooltip: showNew ? 'Hide password' : 'Show password',
                onPressed: () => setState(() => showNew = !showNew),
                icon: PasswordEye(open: showNew),
              ),
            ),
            validator: newPasswordError,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmation,
            obscureText: !showConfirmation,
            decoration: InputDecoration(
              labelText: 'Confirm new password',
              suffixIcon: IconButton(
                tooltip: showConfirmation ? 'Hide password' : 'Show password',
                onPressed: () =>
                    setState(() => showConfirmation = !showConfirmation),
                icon: PasswordEye(open: showConfirmation),
              ),
            ),
            validator: (v) => v != password.text
                ? 'The passwords don’t match.'
                : requiredValidator(v),
          ),
          const SizedBox(height: 24),
          HarvestButton(
            label: 'Update password',
            onPressed: HarvestScope.of(context).busy
                ? null
                : () async {
                    if (!form.currentState!.validate()) return;
                    final result = await HarvestScope.of(context)
                        .changePassword(old.text, password.text);
                    if (!context.mounted) return;
                    if (result != null) {
                      notice(context, result, isError: true);
                    } else {
                      old.clear();
                      password.clear();
                      confirmation.clear();
                      setState(() => submitted = true);
                    }
                  },
          ),
          if (HarvestScope.of(context).live) ...[
            const SizedBox(height: 28),
            const EmailSecurityPanel(),
            const SizedBox(height: 20),
            const ChangeEmailPanel(),
          ],
          if (submitted) ...[
            const SizedBox(height: 20),
            const InfoNote('Your password has been updated.'),
          ],
        ],
      ),
    ),
  );
}
