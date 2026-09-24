import 'package:flutter/foundation.dart';

class Farmer {
  const Farmer(
    this.id,
    this.name,
    this.initials,
    this.market,
    this.location,
    this.distance,
    this.story,
  );
  final String id, name, initials, market, location, story;
  final double distance;
}

const farmers = [
  Farmer(
    'green',
    'Green Valley Farm',
    'GV',
    'Sunday Farmers Market',
    'Clifton',
    3.2,
    'A family farm growing seasonal vegetables with care for the soil. Freshly picked produce, simple growing practices, and a little love in every harvest.',
  ),
  Farmer(
    'sun',
    'Sunrise Orchards',
    'SO',
    'Fresh Market',
    'Gulshan',
    7.5,
    'Sun-ripened fruit from a small family orchard. We pick in small batches so every basket reaches you at its seasonal best.',
  ),
  Farmer(
    'meadow',
    'Meadow & Milk',
    'MM',
    'Sunday Farmers Market',
    'Clifton',
    4.8,
    'Your neighborhood source for dairy and pantry staples. Thoughtfully produced food from people who love what they do.',
  ),
];

class Product {
  const Product(
    this.id,
    this.name,
    this.category,
    this.price,
    this.unit,
    this.stock,
    this.farmerId,
    this.symbol,
    this.color,
    this.description, {
    this.organic = false,
  });
  final String id, name, category, unit, farmerId, symbol, description;
  final int price, stock, color;
  final bool organic;
  Farmer get farmer => farmers.firstWhere((f) => f.id == farmerId);
}

const categories = [
  'All',
  'Vegetables',
  'Fruits',
  'Grains',
  'Dairy',
  'Pulses',
  'Herbs',
  'Organic',
];
const products = [
  Product(
    'tomato',
    'Vine tomatoes',
    'Vegetables',
    180,
    'kg',
    24,
    'green',
    '🍅',
    0xFFF7E5DC,
    'Juicy, vine-ripened tomatoes picked for their bright flavor. A lovely addition to fresh salads, sauces, and everyday cooking.',
    organic: true,
  ),
  Product(
    'avocado',
    'Creamy avocados',
    'Fruits',
    320,
    'pair',
    12,
    'sun',
    '🥑',
    0xFFE6EDCF,
    'Rich, buttery avocados. Let them soften at room temperature and enjoy on toast or in a fresh salad.',
    organic: true,
  ),
  Product(
    'carrot',
    'Garden carrots',
    'Vegetables',
    140,
    'kg',
    18,
    'green',
    '🥕',
    0xFFF9E9D2,
    'Crunchy, naturally sweet carrots from our seasonal harvest. Delicious raw, roasted, or added to your favorite soup.',
  ),
  Product(
    'strawberry',
    'Sweet strawberries',
    'Fruits',
    450,
    'box',
    8,
    'sun',
    '🍓',
    0xFFF7DFE3,
    'A small box of bright, fragrant strawberries. Keep chilled and wash just before enjoying.',
  ),
  Product(
    'milk',
    'Fresh farm milk',
    'Dairy',
    220,
    'litre',
    15,
    'meadow',
    '🥛',
    0xFFE5EAF2,
    'Fresh pasteurized milk for your breakfast, baking, and daily cup of tea. Keep refrigerated.',
  ),
  Product(
    'wheat',
    'Whole wheat',
    'Grains',
    160,
    'kg',
    30,
    'meadow',
    '🌾',
    0xFFF1E7CB,
    'Wholesome, locally grown wheat. A versatile pantry staple for nourishing home-cooked meals.',
  ),
  Product(
    'basil',
    'Fresh basil',
    'Herbs',
    90,
    'bunch',
    0,
    'green',
    '🌿',
    0xFFDEEDD9,
    'Aromatic basil leaves for homemade pesto, salads, and tomato dishes. Save it to your wishlist for your next shop.',
    organic: true,
  ),
  Product(
    'lentil',
    'Red lentils',
    'Pulses',
    280,
    'kg',
    20,
    'meadow',
    '🫘',
    0xFFF4E0D0,
    'Quick-cooking red lentils for comforting dals and soups. A simple, nourishing addition to your pantry.',
  ),
];

class CustomerProfile {
  CustomerProfile({
    this.name = 'Alex Morgan',
    this.email = 'alex@example.com',
    this.phone = '0300 1234567',
    this.address = '12 Garden Street, Clifton, Karachi',
  });
  String name, email, phone, address;
}

class OrderLine {
  const OrderLine(this.product, this.quantity);
  final Product product;
  final int quantity;
  int get total => product.price * quantity;
}

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.date,
    required this.lines,
    required this.address,
    required this.pickups,
    this.status = 'Pending',
  });
  final String id, address;
  final DateTime date;
  final List<OrderLine> lines;
  final Map<String, String> pickups;
  String status;
  int get total => lines.fold(0, (sum, l) => sum + l.total);
}

class CustomerNotice {
  CustomerNotice(this.title, this.message, {this.read = false});
  final String title, message;
  bool read;
}

class CustomerStore extends ChangeNotifier {
  CustomerProfile profile = CustomerProfile();
  final Map<String, int> cart = {};
  final Set<String> wishlist = {};
  final Set<String> followed = {};
  final Map<String, int> purchased = {};
  final List<CustomerOrder> orders = [];
  final List<CustomerNotice> notices = [
    CustomerNotice(
      'Welcome to your local harvest',
      'Explore the sample catalog and follow your favorite farms. This is a customer screen preview; data resets when the app restarts.',
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
    notifyListeners();
  }

  void toggleFollow(String id) {
    followed.contains(id) ? followed.remove(id) : followed.add(id);
    notifyListeners();
  }

  bool add(Product p, [int quantity = 1]) {
    final next = (cart[p.id] ?? 0) + quantity;
    if (quantity < 1 || next > stock(p)) {
      return false;
    }
    cart[p.id] = next;
    notifyListeners();
    return true;
  }

  void quantity(Product p, int value) {
    if (value <= 0) {
      cart.remove(p.id);
    } else if (value <= stock(p)) {
      cart[p.id] = value;
    }
    notifyListeners();
  }

  void clearCart() {
    cart.clear();
    notifyListeners();
  }

  void updateProfile(CustomerProfile value) {
    profile = value;
    notifyListeners();
  }

  CustomerOrder? checkout(String address, Map<String, String> pickups) {
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
    profile = CustomerProfile();
    cart.clear();
    wishlist.clear();
    followed.clear();
    purchased.clear();
    orders.clear();
    notices.clear();
    notifyListeners();
  }
}

String money(num amount) => 'Rs. ${amount.toStringAsFixed(0)}';
String dateLabel(DateTime date) => '${date.day}/${date.month}/${date.year}';
List<String> pickupSlots() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final next = DateTime.now().add(const Duration(days: 2));
  return [
    '${dateLabel(tomorrow)} · 9:00–11:00 AM',
    '${dateLabel(tomorrow)} · 2:00–4:00 PM',
    '${dateLabel(next)} · 9:00–11:00 AM',
  ];
}
