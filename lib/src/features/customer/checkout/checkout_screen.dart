part of '../customer.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _note = TextEditingController();
  bool _busy = false;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final account = HarvestScope.of(context).account;
      _name.text = account.name;
      _phone.text = account.phone;
      _address.text = account.address;
    }
  }

  @override
  void dispose() {
    for (final controller in [_name, _phone, _address, _note]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _confirm() async {
    if (_busy || !_form.currentState!.validate()) return;
    final store = HarvestScope.of(context);
    setState(() => _busy = true);
    try {
      final created = await store.checkout(
        _address.text.trim(),
        recipientName: _name.text.trim(),
        phone: normalizePhoneNumber(_phone.text),
        note: _note.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ConfirmationScreen(orders: created)),
      );
    } catch (e) {
      if (!mounted) return;
      notice(context, e.toString(), isError: true);
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    final palette = Harvest.colors(context);
    if (store.isDemo) {
      return const GuestAccountPrompt(title: 'Sign in to place your order');
    }
    return Scaffold(
      backgroundColor: palette.canvas,
      appBar: AppBar(title: const Text('Review Order')),
      body: Form(
        key: _form,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
          children: [
            const PageHeading(
              'Order Confirmation',
              subtitle: 'Review your details and items before confirming. No online payment is collected.',
            ),
            const SizedBox(height: 20),
            _heading('Delivery Details'),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-name'),
              controller: _name,
              enabled: !_busy,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.name],
              decoration: const InputDecoration(labelText: 'Full name'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter your full name.'
                  : v.trim().length > 500
                  ? 'Use 500 characters or fewer.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-phone'),
              controller: _phone,
              enabled: !_busy,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.telephoneNumber],
              decoration: const InputDecoration(
                labelText: 'Phone number',
                errorMaxLines: 2,
              ),
              validator: (v) => phoneNumberError(v),
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-address'),
              controller: _address,
              enabled: !_busy,
              minLines: 2,
              maxLines: 3,
              keyboardType: TextInputType.streetAddress,
              autofillHints: const [AutofillHints.fullStreetAddress],
              decoration: const InputDecoration(labelText: 'Contact address'),
              validator: (v) => v == null || v.trim().isEmpty
                  ? 'Enter your contact address.'
                  : v.trim().length > 500
                  ? 'Use 500 characters or fewer.'
                  : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('checkout-note'),
              controller: _note,
              enabled: !_busy,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Note for the farmer (optional)',
              ),
              validator: (v) => (v?.trim().length ?? 0) > 1000
                  ? 'Use 1,000 characters or fewer.'
                  : null,
            ),
            const SizedBox(height: 24),
            _heading('Payment Method'),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.radio_button_checked, color: palette.forest),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cash on Delivery',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Pay the farmer in cash when you receive or pick up your order.',
                        style: TextStyle(color: palette.muted, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            _heading('Ordered Items'),
            const SizedBox(height: 16),
            for (final entry in store.basket.entries)
              if (store.product(entry.key) case final product?)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        '${entry.value}x',
                        style: TextStyle(
                          color: palette.forest,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(product.name)),
                      const SizedBox(width: 12),
                      Text(
                        money(product.price * entry.value),
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
            const Divider(height: 28),
            Row(
              children: [
                Expanded(child: _heading('Total to confirm')),
                Text(
                  money(store.basketTotal),
                  style: Harvest.editorial(26, color: palette.forest),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAction(
        child: HarvestButton(
          label: 'Confirm order · ${money(store.basketTotal)}',
          busy: _busy,
          onPressed: _busy || store.basket.isEmpty ? null : _confirm,
        ),
      ),
    );
  }

  Widget _heading(String title) => Text(
    title,
    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
  );
}

/// Today's Weather & Crop Notes Screen matching Reference Image 1 (Screen 3)
