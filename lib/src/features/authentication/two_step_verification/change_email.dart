import 'package:flutter/material.dart';

import '../../common/shared/components.dart';
import '../authentication.dart';

class ChangeEmailPanel extends StatefulWidget {
  const ChangeEmailPanel({super.key});
  @override
  State<ChangeEmailPanel> createState() => _ChangeEmailPanelState();
}

class _ChangeEmailPanelState extends State<ChangeEmailPanel> {
  final form = GlobalKey<FormState>();
  final email = TextEditingController(), password = TextEditingController();
  bool busy = false;
  String? message;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Change email address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Current: ${HarvestScope.of(context).account.email}'),
            const SizedBox(height: 16),
            TextFormField(
              controller: email,
              keyboardType: TextInputType.emailAddress,
              autocorrect: false,
              validator: emailValidator,
              decoration: const InputDecoration(labelText: 'New email address'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: password,
              obscureText: true,
              validator: requiredValidator,
              decoration: const InputDecoration(labelText: 'Current password'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (!form.currentState!.validate()) return;
                      setState(() {
                        busy = true;
                        message = null;
                      });
                      final error = await HarvestScope.of(context)
                          .changeEmail(password.text, email.text);
                      if (!mounted) return;
                      setState(() {
                        busy = false;
                        if (error == null) password.clear();
                        message =
                            error ??
                            'Verification link sent to ${email.text.trim()}. Open it, then sign in with your new email address.';
                      });
                    },
              child: Text(busy ? 'Sending…' : 'Verify new email'),
            ),
            if (message != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(message!),
              ),
          ],
        ),
      ),
    ),
  );
}
