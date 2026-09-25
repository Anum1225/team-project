import '../services/firebase_customer_service.dart';

import 'package:flutter/material.dart';

import '../data/pickup_slots.dart';
import '../data/sample_catalog.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../utils/formatters.dart';
import '../utils/navigation.dart';
import '../validation/customer_validators.dart';
import '../validation/validate_customer_form.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/customer_form.dart';
import '../widgets/customer_text_field.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';
import '../widgets/price_row.dart';
import '../widgets/surface.dart';
import 'success_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final form = GlobalKey<FormState>();
  late final address = TextEditingController(
    text: widget.store.profile.address,
  );
  final Map<String, String> pickups = {};
  bool placing = false;
  final availableSlots = pickupSlots();
  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  Future<void> placeOrder() async {
    if (placing || !validateCustomerForm(form)) {
      return;
    }
    setState(() => placing = true);
    try {
      final order = await widget.store.submitOrder(address.text, pickups);
      if (!mounted) return;
      if (order == null) {
        setState(() => placing = false);
        toast(
          context,
          'Check your basket and choose a pickup slot for every farm.',
        );
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SuccessScreen(order: order, store: widget.store),
        ),
      );
    } catch (e) {
      if (mounted) toast(context, FirebaseCustomerService.errorMessage(e));
    } finally {
      if (mounted) setState(() => placing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final farms = store.cart.keys
        .map((id) => store.product(id).farmerId)
        .toSet();
    return CustomerAccessGate(
      store: widget.store,
      title: 'Checkout',
      child: PageFrame(
        title: 'Checkout',
        child: CustomerForm(
          formKey: form,
          children: [
            const Heading(
              'One step closer to fresh',
              subtitle: 'Review your basket and plan your pickup.',
            ),
            const Surface(
              color: lime,
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: green),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Simulated order · No charge\nYour order is saved to your account.',
                      style: TextStyle(color: green, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Heading('01  Contact & address'),
            Text(
              '${store.profile.name} · ${store.profile.phone}',
              style: const TextStyle(color: muted),
            ),
            const SizedBox(height: 14),
            CustomerTextField(
              controller: address,
              kind: CustomerFieldKind.address,
              label: 'Confirm your address',
              helperText: 'Contact address only. This order is collected at the market.',
            ),
            const SizedBox(height: 26),
            const Heading('02  Choose your pickup'),
            ...farms.map((id) {
              final farmer = farmers.firstWhere((f) => f.id == id);
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Surface(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: green,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${farmer.market} · ${farmer.location}',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Available pickup slots',
                        ),
                        items: availableSlots
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(
                                  s,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        validator: (v) => CustomerValidators.selection(
                          v,
                          availableSlots,
                          'pickup time',
                        ),
                        onChanged: (v) => pickups[id] = v!,
                      ),
                    ],
                  ),
                ),
              );
            }),
            const Heading('03  Review your order'),
            Surface(
              child: Column(
                children: [
                  ...store.cart.entries.map(
                    (e) => PriceRow(
                      '${store.product(e.key).name} × ${e.value}',
                      money(store.product(e.key).price * e.value),
                    ),
                  ),
                  const Divider(),
                  const PriceRow('Pickup', 'Free'),
                  PriceRow('Total', money(store.subtotal), bold: true),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: placing || store.cart.isEmpty ? null : placeOrder,
              child: const Text('Confirm simulated order'),
            ),
          ],
        ),
      ),
    );
  }
}
