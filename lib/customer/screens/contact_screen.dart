import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/customer_form.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/surface.dart';

class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  bool busy = false;
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.profile.name);
  late final email = TextEditingController(text: widget.store.profile.email);
  final message = TextEditingController();
  static const subjects = [
    'General question',
    'Order help',
    'Pickup help',
    'Feedback',
  ];
  String subject = subjects.first;
  @override
  void dispose() {
    name.dispose();
    email.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: widget.store,
    title: 'Contact us',
    child: PageFrame(
      title: 'Contact us',
      child: CustomerForm(
        formKey: form,
        children: [
          const Heading(
            'Let’s talk fresh',
            subtitle:
                'A question, an idea, or a little feedback? We are listening.',
          ),
          const Surface(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.mail_outline, color: green),
                  title: Text('Email support'),
                  subtitle: Text('Support email will be added before launch'),
                ),
                ListTile(
                  leading: Icon(Icons.phone_outlined, color: green),
                  title: Text('Phone'),
                  subtitle: Text('Support number will be added before launch'),
                ),
                ListTile(
                  leading: Icon(Icons.location_on_outlined, color: green),
                  title: Text('Office'),
                  subtitle: Text('Office address will be added before launch'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Heading('Send a little note'),
          CustomerTextField(controller: name, kind: CustomerFieldKind.name),
          const SizedBox(height: 16),
          CustomerTextField(controller: email, kind: CustomerFieldKind.email),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: subject,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            validator: (v) =>
                CustomerValidators.selection(v, subjects, 'subject'),
            decoration: const InputDecoration(labelText: 'Subject'),
            items: subjects
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (v) => subject = v!,
          ),
          const SizedBox(height: 16),
          CustomerTextField(
            controller: message,
            kind: CustomerFieldKind.message,
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!validateCustomerForm(form)) return;
                    setState(() => busy = true);
                    try {
                      await widget.store.sendFeedback(
                        name.text.trim(),
                        email.text.trim(),
                        subject,
                        message.text.trim(),
                      );
                      if (context.mounted) {
                        toast(context, 'Feedback saved. Thank you!');
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) {
                        toast(context, FirebaseCustomerService.errorMessage(e));
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: const Text('Send feedback'),
          ),
        ],
      ),
    ),
  );
}
