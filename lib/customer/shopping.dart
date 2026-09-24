import 'package:flutter/material.dart';

import 'store.dart';
import 'ui.dart';
import 'app.dart' show requiredValue;

class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.store});
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      title: 'Your basket',
      actions: [
        if (store.cart.isNotEmpty)
          TextButton(
            onPressed: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Empty your basket?'),
                  content: const Text(
                    'All items will be removed from your basket.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Keep items'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Clear basket'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                store.clearCart();
              }
            },
            child: const Text('Clear all'),
          ),
      ],
      child: store.cart.isEmpty
          ? EmptyState(
              Icons.shopping_basket_outlined,
              'Your next fresh start',
              'Your basket is waiting for something delicious.',
              action: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Continue shopping'),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Heading(
                  'A basket full of goodness',
                  subtitle: '${store.cartCount} items from your local growers',
                ),
                ...store.cart.entries.map((e) {
                  final p = store.product(e.key);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Surface(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 68,
                            height: 82,
                            child: ProductArt(p, size: 37),
                          ),
                          const SizedBox(width: 13),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: green,
                                  ),
                                ),
                                Text(
                                  '${money(p.price)} / ${p.unit}',
                                  style: const TextStyle(color: muted),
                                ),
                                Wrap(
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  spacing: 10,
                                  children: [
                                    QuantityPicker(
                                      value: e.value,
                                      max: store.stock(p),
                                      onChanged: (q) => store.quantity(p, q),
                                    ),
                                    Text(
                                      money(p.price * e.value),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Remove ${p.name}',
                            onPressed: () => store.quantity(p, 0),
                            icon: const Icon(Icons.close, size: 18),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 14),
                Surface(
                  child: Column(
                    children: [
                      PriceRow('Subtotal', money(store.subtotal)),
                      const PriceRow('Pickup', 'Free'),
                      const Divider(),
                      PriceRow('Total', money(store.subtotal), bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'A simulated checkout. No payment will be collected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () =>
                      openPage(context, CheckoutScreen(store: store)),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Continue to checkout'),
                ),
              ],
            ),
    ),
  );
}

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
  @override
  void dispose() {
    address.dispose();
    super.dispose();
  }

  void placeOrder() {
    if (placing || !form.currentState!.validate()) {
      return;
    }
    setState(() => placing = true);
    final order = widget.store.checkout(address.text, pickups);
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
  }

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final farms = store.cart.keys
        .map((id) => store.product(id).farmerId)
        .toSet();
    return PageFrame(
      title: 'Checkout',
      child: Form(
        key: form,
        child: ListView(
          padding: const EdgeInsets.all(24),
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
                      'Demo order · No charge\nYour order is saved for this session only.',
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
            TextFormField(
              controller: address,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Confirm your address',
                helperText: 'Contact address only. This order is collected at the market.',
              ),
              validator: requiredValue,
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
                        items: pickupSlots()
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
                        validator: (v) =>
                            v == null ? 'Choose a pickup time' : null,
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

class SuccessScreen extends StatelessWidget {
  const SuccessScreen({super.key, required this.order, required this.store});
  final CustomerOrder order;
  final CustomerStore store;
  @override
  Widget build(BuildContext context) => PageFrame(
    title: 'Order placed',
    child: ListView(
      padding: const EdgeInsets.all(30),
      children: [
        const SizedBox(height: 25),
        const CircleAvatar(
          radius: 52,
          backgroundColor: lime,
          child: Icon(Icons.check_rounded, size: 55, color: green),
        ),
        const SizedBox(height: 25),
        const Text(
          'Good things are growing.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            color: green,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Your simulated order ${order.id} has been placed.\nThank you for supporting your local growers.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.7),
        ),
        const SizedBox(height: 28),
        Surface(
          child: Column(
            children: [
              PriceRow('Order number', order.id),
              PriceRow('Placed on', dateLabel(order.date)),
              const PriceRow('Status', 'Pending'),
              PriceRow('Total', money(order.total), bold: true),
            ],
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => OrderScreen(store: store, order: order),
            ),
          ),
          child: const Text('View order & pickup details'),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          child: const Text('Continue shopping'),
        ),
      ],
    ),
  );
}

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key, required this.store, required this.onBrowse});
  final CustomerStore store;
  final VoidCallback onBrowse;
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  String filter = 'All';
  @override
  Widget build(BuildContext context) {
    final orders = widget.store.orders
        .where(
          (o) =>
              filter == 'All' ||
              (filter == 'Active'
                  ? !['Completed', 'Cancelled'].contains(o.status)
                  : o.status == filter),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const Heading(
          'Your orders',
          subtitle: 'Every basket has a story. Here are yours.',
        ),
        Wrap(
          spacing: 8,
          children: ['All', 'Active', 'Completed', 'Cancelled']
              .map(
                (s) => ChoiceChip(
                  label: Text(s),
                  selected: filter == s,
                  onSelected: (_) => setState(() => filter = s),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        if (orders.isEmpty)
          EmptyState(
            Icons.receipt_long_outlined,
            'No orders here yet',
            'Your orders and pickup bookings will appear here after checkout.',
            action: FilledButton(
              onPressed: widget.onBrowse,
              child: const Text('Find something fresh'),
            ),
          ),
        ...orders.map(
          (o) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          o.id,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: green,
                          ),
                        ),
                      ),
                      Tag(o.status),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(dateLabel(o.date), style: const TextStyle(color: muted)),
                  const SizedBox(height: 12),
                  Text(
                    o.lines
                        .map((l) => '${l.product.name} × ${l.quantity}')
                        .join(' · '),
                  ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          money(o.total),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 19,
                            color: green,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => openPage(
                          context,
                          OrderScreen(store: widget.store, order: o),
                        ),
                        child: const Text('View details'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class OrderScreen extends StatelessWidget {
  const OrderScreen({super.key, required this.store, required this.order});
  final CustomerStore store;
  final CustomerOrder order;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) => PageFrame(
      title: 'Order ${order.id}',
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Heading(
            'Your harvest, on its way',
            subtitle: 'Placed ${dateLabel(order.date)} · Simulated order',
            trailing: Tag(order.status),
          ),
          Surface(
            child: Column(
              children:
                  ['Pending', 'Confirmed', 'Ready for Pickup', 'Completed']
                      .map(
                        (s) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            order.status == s
                                ? Icons.radio_button_checked
                                : Icons.radio_button_unchecked,
                            color: order.status == s ? green : muted,
                          ),
                          title: Text(s),
                          trailing: order.status == s
                              ? const Tag('Current')
                              : null,
                        ),
                      )
                      .toList(),
            ),
          ),
          const SizedBox(height: 24),
          const Heading('In your basket'),
          ...order.lines.map(
            (l) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: SizedBox(
                width: 50,
                height: 50,
                child: ProductArt(l.product, size: 28),
              ),
              title: Text(l.product.name),
              subtitle: Text(
                '${l.quantity} × ${money(l.product.price)} / ${l.product.unit}',
              ),
              trailing: Text(money(l.total)),
            ),
          ),
          const Divider(),
          PriceRow('Total', money(order.total), bold: true),
          const SizedBox(height: 24),
          const Heading('Pickup bookings'),
          ...order.lines.map((l) => l.product.farmerId).toSet().map((id) {
            final f = farmers.firstWhere((f) => f.id == id);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Surface(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      f.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${f.market} · ${f.location}'),
                    const SizedBox(height: 10),
                    Text(
                      order.pickups[id] ?? 'No pickup booked',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 12),
                    if (!['Completed', 'Cancelled'].contains(order.status))
                      OutlinedButton.icon(
                        onPressed: () => openPage(
                          context,
                          PickupScreen(store: store, order: order, farmer: f),
                        ),
                        icon: const Icon(Icons.edit_calendar_outlined),
                        label: Text(
                          order.pickups.containsKey(id)
                              ? 'Manage booking'
                              : 'Book a pickup',
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
          const Heading('Contact address'),
          Surface(
            child: Text(order.address, style: const TextStyle(height: 1.6)),
          ),
        ],
      ),
    ),
  );
}

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
  @override
  Widget build(BuildContext context) {
    final slots = {?selected, ...pickupSlots()}.toList();
    return PageFrame(
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
            onPressed: selected == null
                ? null
                : () {
                    widget.store.updatePickup(
                      widget.order,
                      widget.farmer.id,
                      selected,
                    );
                    Navigator.pop(context);
                  },
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
                  widget.store.updatePickup(
                    widget.order,
                    widget.farmer.id,
                    null,
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Cancel pickup booking'),
            ),
        ],
      ),
    );
  }
}
