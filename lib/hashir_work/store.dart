import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';

/// Shared view state and domain operations used by screens and store implementations.
class HarvestStore extends ChangeNotifier {
  bool get live => false;
  bool get isDemo => false;
  bool get canManageShop =>
      authenticated &&
      !isDemo &&
      (role == UserRole.admin || role == UserRole.farmer);
  bool get canShop => !isDemo && authenticated && role == UserRole.customer;
  bool get authenticated => true;
  bool loading = false;
  bool busy = false;
  String? error;
  Map<String, dynamic>? report;

  Future<void> refresh() async {}
  Future<void> loadMore() async {}
  bool get hasMore => false;
  Future<void> loadReport(int days) async {}
  Future<Map<String, dynamic>> fetchReport(int days) async => report ?? {};
  Future<void> signOut() async {}

  Future<String?> signIn(
    String email,
    String password,
    UserRole selected,
  ) async => 'Authentication is unavailable in a test preview.';

  Future<String?> register(
    String email,
    String password,
    String name,
    String phone,
    String address,
    UserRole selected,
  ) async => 'Registration is unavailable in a test preview.';

  Future<String?> resetPassword(String email) async =>
      'Account service unavailable.';
  Future<String?> changePassword(String old, String password) async =>
      'Account service unavailable.';
  Future<String?> sendFeedback(String email, String message) async =>
      'Account service unavailable.';

  Future<String?> saveAccount(Account value) async {
    changed();
    return null;
  }

  Future<String?> saveFarm(Farm value) async {
    changed();
    return null;
  }

  final capabilities = const FeatureCapabilities(
    pickup: true,
    notifications: true,
    following: true,
  );
  final Set<String> followed = {};
  final Set<String> readNotices = {};
  final Map<String, String> bookingSlots = {};

  final StreamController<({String title, String message})> _alerts =
      StreamController.broadcast();

  /// Live alerts (order status changes, restocks) for in-app banners.
  Stream<({String title, String message})> get alerts => _alerts.stream;

  void pushAlert(String title, String message) {
    if (!_alerts.isClosed) _alerts.add((title: title, message: message));
  }

  @override
  void dispose() {
    _alerts.close();
    super.dispose();
  }

  /// Administrator contact details shown on Contact Us (appConfig/contact).
  final Map<String, String> contactInfo = {};

  /// Restock alerts for saved products and followed farms, newest first.
  final List<({String id, String title, String message})> restockAlerts = [];

  /// Records restocks: products that went from sold out to in stock, or new
  /// products from followed farms. Returns the alerts that were added.
  List<({String id, String title, String message})> detectRestocks(
    Map<String, int> previousStock,
    Iterable<Product> current,
  ) {
    if (previousStock.isEmpty) return const [];
    final added = <({String id, String title, String message})>[];
    for (final p in current) {
      final before = previousStock[p.id];
      final restocked = before == 0 && p.stock > 0;
      final newFromFollowed =
          before == null && p.stock > 0 && followed.contains(p.farmId);
      if (!(restocked &&
              (saved.contains(p.id) || followed.contains(p.farmId))) &&
          !newFromFollowed) {
        continue;
      }
      final id = 'restock-${p.id}-${p.stock}';
      if (restockAlerts.any((a) => a.id == id)) continue;
      final alert = (
        id: id,
        title: restocked
            ? '${p.name} is back in stock'
            : 'New from a farm you follow',
        message: '${farm(p.farmId).name} · ${p.stock} ${p.unit} available',
      );
      restockAlerts.insert(0, alert);
      added.add(alert);
    }
    if (restockAlerts.length > 50) {
      restockAlerts.removeRange(50, restockAlerts.length);
    }
    return added;
  }

  List<({String id, String title, String message})> get customerNotices => [
    ...restockAlerts,
    for (final order in visibleOrders)
      (
        id: '${order.id}-${order.status.name}',
        title: 'Order ${order.status.label}',
        message: '${order.farmName} · ${order.id}',
      ),
    for (final entry in bookingSlots.entries)
      (
        id: 'pickup-${entry.key}-${entry.value}',
        title: 'Pickup booked',
        message: '${entry.key} · ${entry.value}',
      ),
  ];
  Future<String?> toggleFollow(String id) async {
    if (!canShop) return 'Sign in to follow farms.';
    followed.contains(id) ? followed.remove(id) : followed.add(id);
    changed();
    return null;
  }

  Future<String?> markNoticesRead() async {
    if (!canShop) return 'Please sign in.';
    readNotices.addAll(customerNotices.map((n) => n.id));
    changed();
    return null;
  }

  Future<String?> savePickup(HarvestOrder order, String? slot) async {
    if (!canShop || order.customerId != account.id || !order.status.active) {
      return 'This pickup cannot be changed.';
    }
    if (slot == null) {
      bookingSlots.remove(order.id);
    } else {
      bookingSlots[order.id] = slot;
    }
    changed();
    return null;
  }

  final List<Account> accounts = [];
  final List<Farm> farms = [];
  final List<Product> products = [];
  final List<HarvestOrder> orders = [];
  final List<String> categories = [];
  final Map<String, int> categoryCounts = {};
  final Map<String, int> basket = {};
  final Set<String> saved = {};
  final List<String> recentSearches = [];
  UserRole role = UserRole.customer;
  int _sequence = 1050;

  Account get account => accounts.firstWhere((a) => a.role == role);
  Farm get ownFarm => farms.firstWhere((f) => f.owner == account.id);
  Farm farm(String id) => farms.firstWhere((f) => f.id == id);
  Product? product(String id) => products.cast<Product?>().firstWhere(
    (p) => p?.id == id,
    orElse: () => null,
  );

  List<Product> get visibleProducts => role == UserRole.farmer
      ? products.where((p) => p.farmId == ownFarm.id).toList()
      : products.toList();

  List<HarvestOrder> get visibleOrders =>
      orders
          .where(
            (o) => switch (role) {
              UserRole.customer => o.customerId == account.id,
              UserRole.farmer => o.farmId == ownFarm.id,
              UserRole.admin => true,
            },
          )
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int get basketCount => basket.values.fold(0, (a, b) => a + b);
  int get basketTotal => basket.entries.fold(
    0,
    (a, e) => a + (product(e.key)?.price ?? 0) * e.value,
  );

  bool canManage(Product p) =>
      role == UserRole.admin ||
      (role == UserRole.farmer && p.farmId == ownFarm.id);

  void chooseRole(UserRole value) {
    role = value;
    notifyListeners();
  }

  void toggleSaved(String id) {
    if (role != UserRole.customer) return;
    saved.contains(id) ? saved.remove(id) : saved.add(id);
    notifyListeners();
  }

  void rememberSearch(String query) {
    final value = query.trim();
    if (value.isEmpty) return;
    recentSearches.remove(value);
    recentSearches.insert(0, value);
    if (recentSearches.length > 5) recentSearches.removeLast();
  }

  String? setQuantity(String id, int quantity) {
    if (!canShop) return 'Sign in as a customer to add to your basket.';
    final p = product(id);
    if (quantity <= 0) {
      basket.remove(id);
      notifyListeners();
      return null;
    }
    if (p == null) return 'This product is no longer available.';
    if (quantity > p.stock) return 'Only ${p.stock} ${p.unit} available.';
    if (!accounts.firstWhere((a) => a.id == farm(p.farmId).owner).active) {
      return 'This farm is currently unavailable.';
    }
    basket[id] = quantity;
    notifyListeners();
    return null;
  }

  void clearBasket() {
    if (isDemo) return;
    basket.clear();
    notifyListeners();
  }

  FutureOr<List<HarvestOrder>> checkout(
    String address, {
    CheckoutDetails? details,
  }) {
    if (!canShop || !account.active) {
      throw StateError('This account cannot place orders.');
    }
    if (address.trim().isEmpty) throw StateError('Please add your address.');
    if (basket.isEmpty) throw StateError('Your basket is empty.');

    for (final e in basket.entries) {
      final p = product(e.key);
      if (p == null || e.value < 1 || p.stock < e.value) {
        throw StateError(
          '${p?.name ?? 'An item'} is no longer available in that quantity. Update your basket.',
        );
      }
      if (!accounts.firstWhere((a) => a.id == farm(p.farmId).owner).active) {
        throw StateError('${farm(p.farmId).name} is currently unavailable.');
      }
    }

    final groups = <String, List<OrderLine>>{};
    for (final e in basket.entries) {
      final p = product(e.key)!;
      groups
          .putIfAbsent(p.farmId, () => [])
          .add(
            OrderLine(
              productId: p.id,
              name: p.name,
              image: p.image,
              photo: p.photo,
              unit: p.unit,
              price: p.price,
              quantity: e.value,
            ),
          );
    }

    final created = groups.entries
        .map(
          (e) => HarvestOrder(
            id: 'HH-${_sequence++}',
            customerId: account.id,
            customerName: details?.name.trim() ?? account.name,
            farmId: e.key,
            farmName: farm(e.key).name,
            date: DateTime.now(),
            items: List.unmodifiable(e.value),
            address: address.trim(),
            phone: details?.phone.trim() ?? account.phone,
            note: details?.note.trim() ?? '',
            payment: details?.payment ?? PaymentMethod.cashOnDelivery,
          ),
        )
        .toList();

    for (final e in basket.entries) {
      product(e.key)!.stock -= e.value;
    }
    orders.addAll(created);
    basket.clear();
    account.address = address.trim();
    notifyListeners();
    return created;
  }

  FutureOr<String?> updateStatus(HarvestOrder order, OrderStatus status) {
    if (role == UserRole.customer ||
        (role == UserRole.farmer && order.farmId != ownFarm.id)) {
      return 'You do not have access to update this order.';
    }
    if (!order.status.active) return 'This order is already closed.';
    if (status != OrderStatus.cancelled &&
        status.index != order.status.index + 1) {
      return 'Choose the next order status.';
    }
    if (status == OrderStatus.cancelled) {
      for (final line in order.items) {
        final p = product(line.productId);
        if (p != null) p.stock += line.quantity;
      }
    }
    order.status = status;
    notifyListeners();
    return null;
  }

  FutureOr<String?> saveProduct(Product value) {
    final existing = product(value.id);
    if (role == UserRole.customer ||
        (role == UserRole.farmer && value.farmId != ownFarm.id) ||
        (existing != null && !canManage(existing))) {
      return 'You cannot edit this product.';
    }
    if (value.name.trim().isEmpty ||
        value.price < 0 ||
        value.stock < 0 ||
        !categories.contains(value.category)) {
      return 'Check the product details.';
    }
    if (existing != null) products.remove(existing);
    products.add(value);
    notifyListeners();
    return null;
  }

  FutureOr<String?> deleteProduct(Product value) {
    if (!canManage(value)) return 'Access denied.';
    products.remove(value);
    basket.remove(value.id);
    saved.remove(value.id);
    notifyListeners();
    return null;
  }

  FutureOr<String?> saveCategory(String value, {String? previous}) {
    if (role != UserRole.admin) return 'Administrator access is required.';
    final name = value.trim();
    if (name.isEmpty) return 'Enter a category name.';
    if (categories.any(
      (c) => c.toLowerCase() == name.toLowerCase() && c != previous,
    )) {
      return 'This category already exists.';
    }
    if (previous != null) {
      categories.remove(previous);
      for (final p in products.where((p) => p.category == previous)) {
        p.category = name;
      }
    }
    categories.add(name);
    notifyListeners();
    return null;
  }

  FutureOr<String?> deleteCategory(String value) {
    if (role != UserRole.admin) return 'Administrator access is required.';
    if (products.any((p) => p.category == value)) {
      return 'Move this category’s products before removing it.';
    }
    categories.remove(value);
    notifyListeners();
    return null;
  }

  FutureOr<String?> toggleAccount(Account value) {
    if (role != UserRole.admin || value.role == UserRole.admin) {
      return 'Access denied.';
    }
    value.active = !value.active;
    notifyListeners();
    return null;
  }

  void changed() => notifyListeners();
}
