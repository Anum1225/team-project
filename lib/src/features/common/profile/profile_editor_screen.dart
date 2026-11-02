part of 'profile.dart';

class ProfileEditorScreen extends StatefulWidget {
  const ProfileEditorScreen({super.key, this.account});
  final Account? account;
  @override
  State<ProfileEditorScreen> createState() => _ProfileEditorScreenState();
}

class _ProfileEditorScreenState extends State<ProfileEditorScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(),
      phone = TextEditingController(),
      address = TextEditingController();
  bool initialized = false;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    final a = widget.account ?? HarvestScope.of(context).account;
    name.text = a.name;
    phone.text = a.phone;
    address.text = a.address;
  }

  @override
  void dispose() {
    for (final c in [name, phone, address]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.isDemo) {
      return const GuestAccountPrompt(title: 'Personal details');
    }
    return HarvestPage(
      title: 'Personal details',
      bottom: HarvestButton(
        label: 'Save changes',
        onPressed: store.busy
            ? null
            : () async {
                if (!form.currentState!.validate()) return;
                final original = widget.account ?? store.account;
                form.currentState!.save();
                final a = Account(
                  id: original.id,
                  name: name.text.trim(),
                  email: original.email,
                  role: original.role,
                  phone: phone.text.trim(),
                  address: address.text.trim(),
                  avatar: original.avatar,
                  active: original.active,
                );
                final result = await store.saveAccount(a);
                if (!context.mounted) return;
                if (result != null) {
                  notice(context, result, isError: true);
                  return;
                }
                Navigator.pop(context);
                notice(context, 'Your profile has been updated');
              },
      ),
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const PageHeading(
              'Your personal details.',
              subtitle: 'Keep your contact details up to date.',
            ),
            HarvestField(controller: name, label: 'Full name'),
            const SizedBox(height: 16),
            PhoneField(controller: phone, label: 'Mobile phone'),
            const SizedBox(height: 16),
            HarvestField(controller: address, label: 'Address', lines: 3),
            const SizedBox(height: 24),
            InfoNote(
              'Sign-in email: ${(widget.account ?? store.account).email}',
            ),
          ],
        ),
      ),
    );
  }
}
