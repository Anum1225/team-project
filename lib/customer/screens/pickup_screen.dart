import '../services/firebase_customer_service.dart';
import '../utils/navigation.dart';

import 'package:flutter/material.dart';

import '../data/pickup_slots.dart';
import '../models/customer_order.dart';
import '../models/farmer.dart';
import '../state/customer_store.dart';
import '../theme/customer_theme.dart';
import '../widgets/customer_access_gate.dart';
import '../widgets/heading.dart';
import '../widgets/page_frame.dart';

class PickupScreen extends StatefulWidget {
  const PickupScreen({
    super.key,
    required this.store,
    required this.order,
    required this.farmer,
  });
  final CustomerStore store;
  final CustomerOrder order;
  final Farmer farmer;
  @override
  State<PickupScreen> createState() => _PickupScreenState();
}

class _PickupScreenState extends State<PickupScreen> {
  late String? selected = widget.order.pickups[widget.farmer.id];
  bool busy = false;
  Future<void> save(String? slot) async {
    if (busy) return;
    setState(() => busy = true);
    try {
      await widget.store.savePickup(widget.order, widget.farmer.id, slot);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) toast(context, FirebaseCustomerService.errorMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final slots = {?selected, ...pickupSlots()}.toList();
    return CustomerAccessGate(
      store: widget.store,
      title: 'Manage pickup',
      child: PageFrame(
        title: 'Manage pickup',
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Heading(
              widget.farmer.name,
              subtitle: '${widget.farmer.market}\nOrder ${widget.order.id}',
            ),
            const Text(
              'Select a pickup window',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
            ...slots.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  tileColor: selected == s ? lime : Colors.white,
                  leading: Icon(
                    selected == s
                        ? Icons.radio_button_checked
                        : Icons.radio_button_off,
                    color: green,
                  ),
                  title: Text(s),
                  onTap: () => setState(() => selected = s),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: busy || selected == null ? null : () => save(selected),
              child: const Text('Save pickup time'),
            ),
            if (widget.order.pickups.containsKey(widget.farmer.id))
              TextButton(
                onPressed: () async {
                  final cancel = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Cancel this pickup?'),
                      content: const Text(
                        'Your order stays active. You can book another pickup time from order details.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Keep booking'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('Cancel pickup'),
                        ),
                      ],
                    ),
                  );
                  if (cancel == true && context.mounted) {
                    await save(null);
                  }
                },
                child: const Text('Cancel pickup booking'),
              ),
          ],
        ),
      ),
    );
  }
}
