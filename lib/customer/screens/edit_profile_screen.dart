import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../models/customer_profile.dart';
import '../state/customer_store.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/customer_form.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  bool busy = false;
  final form = GlobalKey<FormState>();
  late final name = TextEditingController(text: widget.store.profile.name);
  late final email = TextEditingController(text: widget.store.profile.email);
  late final phone = TextEditingController(text: widget.store.profile.phone);
  late final address = TextEditingController(
    text: widget.store.profile.address,
  );
  @override
  void dispose() {
    for (final c in [name, email, phone, address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CustomerAccessGate(
    store: widget.store,
    title: 'Edit profile',
    child: PageFrame(
      title: 'Edit profile',
      child: CustomerForm(
        formKey: form,
        children: [
          const Heading(
            'Make yourself at home',
            subtitle: 'Keep your contact information up to date.',
          ),
          CustomerTextField(controller: name, kind: CustomerFieldKind.name),
          const SizedBox(height: 18),
          CustomerTextField(
            controller: email,
            kind: CustomerFieldKind.email,
            readOnly: true,
          ),
          const SizedBox(height: 18),
          CustomerTextField(controller: phone, kind: CustomerFieldKind.phone),
          const SizedBox(height: 18),
          CustomerTextField(
            controller: address,
            kind: CustomerFieldKind.address,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: busy
                ? null
                : () async {
                    if (!validateCustomerForm(form)) {
                      return;
                    }
                    setState(() => busy = true);
                    try {
                      await widget.store.saveProfile(
                        CustomerProfile(
                          name: name.text.trim(),
                          email: email.text.trim(),
                          phone: CustomerValidators.normalizePhone(phone.text),
                          address: address.text.trim(),
                        ),
                      );
                      if (!context.mounted) return;
                      toast(context, 'Profile saved');
                      Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted) {
                        toast(context, FirebaseCustomerService.errorMessage(e));
                      }
                    } finally {
                      if (mounted) setState(() => busy = false);
                    }
                  },
            child: const Text('Save changes'),
          ),
        ],
      ),
    ),
  );
}
