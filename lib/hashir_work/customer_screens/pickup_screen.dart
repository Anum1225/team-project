import 'package:flutter/material.dart';

import '../components.dart';
import '../models.dart';
import '../customer_forms/widgets/auth_form_frame.dart';
import '../customer_forms/validation/validate_customer_form.dart';
import 'sign_in_required.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({super.key, required this.order});
  final HarvestOrder order;
  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  final form = GlobalKey<FormState>();
  String? selected;
  bool initialized = false, busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (initialized) return;
    initialized = true;
    selected = HarvestScope.of(context).bookingSlots[widget.order.id];
  }

  Future<void> save({bool cancel = false}) async {
    if (busy || (!cancel && !validateCustomerForm(form))) return;
    if (cancel &&
        !await confirmAction(
          context,
          title: 'Cancel this pickup?',
          message:
              'Your order stays active. You can book another pickup window.',
          action: 'Cancel pickup',
        )) {
      return;
    }
    if (!mounted) return;
    setState(() => busy = true);
    final error = await HarvestScope.of(context)
        .savePickup(widget.order, cancel ? null : selected);
    if (!mounted) return;
    setState(() => busy = false);
    if (error != null) {
      notice(context, error, isError: true);
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = HarvestScope.of(context);
    if (store.isDemo) return const SignInRequired();
    final slots = store.farm(widget.order.farmId).pickupSlots;
    return AuthFormFrame(
      title: 'Manage pickup',
      heading: widget.order.farmName,
      subtitle: 'Order ${widget.order.id}',
      formKey: form,
      busy: busy,
      children: [
        Text(
          slots.isEmpty
              ? 'This farm has not listed pickup times yet. Check back soon.'
              : 'Choose one of the pickup windows offered by this farm.',
        ),
        const SizedBox(height: 20),
        DropdownButtonFormField<String>(
          initialValue: selected,
          isExpanded: true,
          decoration: const InputDecoration(labelText: 'Pickup time'),
          items: {?selected, ...slots}
              .map(
                (s) => DropdownMenuItem(
                  value: s,
                  child: Text(s, style: const TextStyle(fontSize: 12)),
                ),
              )
              .toList(),
          validator: (v) => v == null ? 'Choose a pickup time.' : null,
          onChanged: (v) => selected = v,
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: widget.order.status.active && slots.isNotEmpty
              ? () => save()
              : null,
          child: const Text('Save pickup time'),
        ),
        if (store.bookingSlots.containsKey(widget.order.id))
          TextButton(
            onPressed: widget.order.status.active
                ? () => save(cancel: true)
                : null,
            child: const Text('Cancel pickup booking'),
          ),
      ],
    );
  }
}
