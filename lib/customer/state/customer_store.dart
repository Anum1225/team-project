import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/sample_catalog.dart';
import '../models/customer_notice.dart';
import '../models/customer_order.dart';
import '../models/customer_profile.dart';
import '../models/customer_session.dart';
import '../models/order_line.dart';
import '../models/product.dart';
import '../services/firebase_customer_service.dart';

class CustomerStore extends ChangeNotifier {
  CustomerStore([this._session = CustomerSession.demo]);

  CustomerStore.connected(this.backend, this.preferences)
    : _session = CustomerSession.demo;

  FirebaseCustomerService? backend;
  SharedPreferences? preferences;
  String? connectionError;
  String? syncError;
  StreamSubscription<List<CustomerOrder>>? _ordersSubscription;
  Future<void> _writes = Future.value();
  bool _disposed = false;
  bool get isConnected => backend != null;

  FirebaseCustomerService get _service =>
      backend ??
      (throw StateError(
        connectionError ??
            'Firebase is not connected. Check the project configuration.',
      ));

  Future<void> restore() async {
    final raw = preferences?.getString('harvesthub.demo.favorites');
    if (raw != null) {
      try {
        _readPreferences(
          Map<String, dynamic>.from(jsonDecode(raw) as Map),
          demo: true,
        );
      } catch (_) {
        /* Ignore a damaged local browsing cache. */
      }
    }
    if (backend?.auth.currentUser != null) {
      try {
        await _activate(await _service.loadProfile());
      } catch (e) {
        connectionError = FirebaseCustomerService.errorMessage(e);
        await _service.auth.signOut();
      }
    }
  }

  Future<void> signIn(String email, String password) async {
    try {
      await _activate(await _service.signIn(email, password));
    } catch (_) {
      await _service.auth.signOut();
      rethrow;
    }
  }

  Future<void> register(CustomerProfile value, String password) async {
    try {
      await _activate(await _service.register(value, password));
    } catch (_) {
      await _service.auth.signOut();
      rethrow;
    }
  }

  Future<void> _activate(CustomerProfile value) async {
    final saved = await _service.loadPreferences();
    _readPreferences(saved, mergeFavorites: isDemo);
    profile = value;
    _session = CustomerSession.customer;
    connectionError = null;
    syncError = null;
    await _ordersSubscription?.cancel();
    _ordersSubscription = _service.watchOrders().listen(
      (incoming) {
        if (_disposed || isDemo) return;
        for (final order in incoming) {
          final old = orders.where((o) => o.id == order.id).firstOrNull;
          if (old != null && old.status != order.status) {
            notices.insert(
              0,
              CustomerNotice(
                'Order status updated',
                '${order.id}: ${order.status}',
              ),
            );
          }
        }
        orders
          ..clear()
          ..addAll(incoming);
        purchased.clear();
        for (final order in orders.where((o) => o.status != 'Cancelled')) {
          for (final line in order.lines) {
            purchased.update(
              line.product.id,
              (q) => q + line.quantity,
              ifAbsent: () => line.quantity,
            );
          }
        }
        notifyListeners();
      },
      onError: (Object error) {
        if (!_disposed) {
          syncError = FirebaseCustomerService.errorMessage(error);
          notifyListeners();
        }
      },
    );
    _persist();
    notifyListeners();
  }

  void _readPreferences(
    Map<String, dynamic> saved, {
    bool demo = false,
    bool mergeFavorites = false,
  }) {
    final ids = products.map((p) => p.id).toSet();
    final farmIds = farmers.map((f) => f.id).toSet();
    if (!mergeFavorites) {
      wishlist.clear();
      followed.clear();
    }
    wishlist.addAll(
      (saved['wishlist'] as List? ?? []).whereType<String>().where(
        ids.contains,
      ),
    );
    followed.addAll(
      (saved['followed'] as List? ?? []).whereType<String>().where(
        farmIds.contains,
      ),
    );
    if (!demo) {
      cart.clear();
      for (final e in (saved['cart'] as Map? ?? {}).entries) {
        if (ids.contains(e.key) && e.value is int && e.value > 0) {
          cart[e.key as String] = e.value as int;
        }
      }
    }
  }

  void _persist() {
    if (backend == null && preferences == null) return;
    final value = <String, dynamic>{
      'wishlist': wishlist.toList(),
      'followed': followed.toList(),
      if (!isDemo) 'cart': Map.of(cart),
    };
    final demo = isDemo;
    final uid = backend?.auth.currentUser?.uid;
    _writes = _writes.then((_) async {
      try {
        if (demo) {
          await preferences?.setString(
            'harvesthub.demo.favorites',
            jsonEncode(value),
          );
        } else if (backend != null && backend!.auth.currentUser?.uid == uid) {
          await backend!.savePreferences(value);
        }
        if (!_disposed) {
          syncError = null;
          notifyListeners();
        }
      } catch (e) {
        if (!_disposed) {
          syncError = FirebaseCustomerService.errorMessage(e);
          notifyListeners();
        }
      }
    });
  }

  Future<void> startDemo() async {
    await _writes;
    if (!isDemo) {
      wishlist.clear();
      followed.clear();
    }
    await backend?.auth.signOut();
    enterDemo();
  }

  Future<void> signOut() async {
    await _writes;
    await backend?.auth.signOut();
    reset();
  }

  Future<void> resetPassword(String email) => _service.resetPassword(email);
  Future<void> changePassword(String current, String next) =>
      _service.changePassword(current, next);
  Future<void> saveProfile(CustomerProfile value) async {
    if (!canShop) throw StateError('Please sign in first.');
    if (backend != null) await _service.saveProfile(value);
    updateProfile(value);
  }

  Future<void> sendFeedback(
    String name,
    String email,
    String subject,
    String message,
  ) async {
    if (!canShop) throw StateError('Please sign in first.');
    await _service.sendFeedback(name, email, subject, message);
  }

  Future<CustomerOrder?> submitOrder(
    String address,
    Map<String, String> pickups,
  ) async {
    if (!canShop) return null;
    if (backend == null) return checkout(address, pickups);
    if (cart.isEmpty ||
        address.trim().isEmpty ||
        cart.entries.any((e) => e.value > stock(product(e.key)))) {
      return null;
    }
    if (cart.keys
        .map((id) => product(id).farmerId)
        .any((id) => !pickups.containsKey(id))) {
      return null;
    }
    final order = CustomerOrder(
      id: _service.newOrderId(),
      date: DateTime.now(),
      lines: cart.entries
          .map((e) => OrderLine(product(e.key), e.value))
          .toList(),
      address: address.trim(),
      pickups: Map.of(pickups),
    );
    await _service.saveOrder(order);
    if (!orders.any((o) => o.id == order.id)) orders.insert(0, order);
    cart.clear();
    notices.insert(
      0,
      CustomerNotice(
        'Order saved',
        'Your simulated order ${order.id} was saved to your account.',
      ),
    );
    _persist();
    notifyListeners();
    return order;
  }

  Future<void> savePickup(
    CustomerOrder order,
    String farmerId,
    String? slot,
  ) async {
    if (!canShop) throw StateError('Please sign in first.');
    if (backend != null) await _service.updatePickup(order, farmerId, slot);
    updatePickup(order, farmerId, slot);
  }

  CustomerSession _session;
  bool get isDemo => _session == CustomerSession.demo;
  bool get canShop => !isDemo;

  void enterDemo() {
    unawaited(_ordersSubscription?.cancel());
    _session = CustomerSession.demo;
    profile = CustomerProfile();
    cart.clear();
    orders.clear();
    purchased.clear();
    notices.clear();
    // Browsing favorites survive a trip to the sign-in screen and back.
    _persist();
    notifyListeners();
  }

  CustomerProfile profile = CustomerProfile();
  final Map<String, int> cart = {};
  final Set<String> wishlist = {};
  final Set<String> followed = {};
  final Map<String, int> purchased = {};
  final List<CustomerOrder> orders = [];
  final List<CustomerNotice> notices = [
    CustomerNotice(
      'Welcome to your local harvest',
      'Explore the sample catalog and save your favorites. Demo browsing does not include shopping or orders; guest favorites are saved on this device.',
    ),
  ];
  int get cartCount => cart.values.fold(0, (a, b) => a + b);
  int get subtotal =>
      cart.entries.fold(0, (sum, e) => sum + product(e.key).price * e.value);
  int get unread => notices.where((n) => !n.read).length;
  Product product(String id) => products.firstWhere((p) => p.id == id);
  int stock(Product p) => p.stock - (purchased[p.id] ?? 0);
  void toggleWish(String id) {
    wishlist.contains(id) ? wishlist.remove(id) : wishlist.add(id);
    _persist();
    notifyListeners();
  }

  void toggleFollow(String id) {
    followed.contains(id) ? followed.remove(id) : followed.add(id);
    _persist();
    notifyListeners();
  }

  bool add(Product p, [int quantity = 1]) {
    if (!canShop) return false;
    final next = (cart[p.id] ?? 0) + quantity;
    if (quantity < 1 || next > stock(p)) {
      return false;
    }
    cart[p.id] = next;
    _persist();
    notifyListeners();
    return true;
  }

  void quantity(Product p, int value) {
    if (!canShop) return;
    if (value <= 0) {
      cart.remove(p.id);
    } else if (value <= stock(p)) {
      cart[p.id] = value;
    }
    _persist();
    notifyListeners();
  }

  void clearCart() {
    if (!canShop) return;
    cart.clear();
    _persist();
    notifyListeners();
  }

  void updateProfile(CustomerProfile value) {
    if (isDemo) return;
    profile = value;
    notifyListeners();
  }

  CustomerOrder? checkout(String address, Map<String, String> pickups) {
    if (!canShop) return null;
    if (cart.isEmpty ||
        address.trim().isEmpty ||
        cart.entries.any((e) => e.value > stock(product(e.key)))) {
      return null;
    }
    final farmerIds = cart.keys.map((id) => product(id).farmerId).toSet();
    if (farmerIds.any((id) => !pickups.containsKey(id))) {
      return null;
    }
    final order = CustomerOrder(
      id: 'HH-${1001 + orders.length}',
      date: DateTime.now(),
      lines: cart.entries
          .map((e) => OrderLine(product(e.key), e.value))
          .toList(),
      address: address.trim(),
      pickups: Map.of(pickups),
    );
    for (final e in cart.entries) {
      purchased[e.key] = (purchased[e.key] ?? 0) + e.value;
    }
    orders.insert(0, order);
    notices.insert(
      0,
      CustomerNotice(
        'Order ${order.id} placed',
        'Your simulated order is pending confirmation. You can review your pickup bookings in Orders.',
      ),
    );
    cart.clear();
    notifyListeners();
    return order;
  }

  void updatePickup(CustomerOrder order, String farmerId, String? slot) {
    if (!canShop) return;
    if (slot == null) {
      order.pickups.remove(farmerId);
    } else {
      order.pickups[farmerId] = slot;
    }
    notices.insert(
      0,
      CustomerNotice(
        'Pickup booking updated',
        'Your pickup for ${order.id} has been ${slot == null ? 'cancelled' : 'rescheduled'}.',
      ),
    );
    notifyListeners();
  }

  void markRead() {
    for (final n in notices) {
      n.read = true;
    }
    notifyListeners();
  }

  void reset() {
    unawaited(_ordersSubscription?.cancel());
    _session = CustomerSession.demo;
    profile = CustomerProfile();
    cart.clear();
    wishlist.clear();
    followed.clear();
    purchased.clear();
    orders.clear();
    notices.clear();
    _persist();
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(_ordersSubscription?.cancel());
    super.dispose();
  }
}
