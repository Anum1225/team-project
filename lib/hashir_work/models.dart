import 'dart:math' as math;
import 'dart:typed_data';

enum UserRole { customer, farmer, admin }

extension RoleName on UserRole {
  String get label => switch (this) {
    UserRole.customer => 'Customer',
    UserRole.farmer => 'Farmer',
    UserRole.admin => 'Administrator',
  };
}

enum OrderStatus { pending, confirmed, ready, completed, cancelled }

extension OrderStatusName on OrderStatus {
  String get label => switch (this) {
    OrderStatus.pending => 'Pending',
    OrderStatus.confirmed => 'Confirmed',
    OrderStatus.ready => 'Ready for pickup',
    OrderStatus.completed => 'Completed',
    OrderStatus.cancelled => 'Cancelled',
  };
  bool get active =>
      this != OrderStatus.completed && this != OrderStatus.cancelled;
}

class Account {
  Account({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.phone = '',
    this.address = '',
    this.active = true,
    this.createdAt,
  });
  final String id;
  String name, email, phone, address;
  final UserRole role;
  bool active;
  final DateTime? createdAt;

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'role': role.name,
    'phone': phone,
    'address': address,
    'active': active,
    if (createdAt != null) 'createdAt': createdAt,
  };
}

class Farm {
  Farm({
    required this.id,
    required this.name,
    required this.owner,
    required this.location,
    required this.market,
    required this.description,
    required this.image,
    this.lat,
    this.lng,
    List<String>? pickupSlots,
  }) : pickupSlots = pickupSlots ?? [];
  final String id, owner;
  String name, location, market, description, image;

  /// Farm coordinates used for distance filtering; null until the farmer sets them.
  double? lat, lng;

  /// Pickup windows the farmer offers, e.g. "Sat · 9:00 AM – 12:00 PM".
  List<String> pickupSlots;
}

/// Great-circle distance in kilometres between two coordinates.
double distanceKm(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(lat2 - lat1), dLng = rad(lng2 - lng1);
  final a =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(lat1)) *
          math.cos(rad(lat2)) *
          math.sin(dLng / 2) *
          math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(a));
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.category,
    required this.farmId,
    required this.price,
    required this.stock,
    required this.image,
    this.unit = 'kg',
    this.description = '',
    this.photo,
  });
  final String id;
  String name, category, farmId, image, unit, description;
  int price, stock;
  Uint8List? photo;
}

class OrderLine {
  const OrderLine({
    required this.productId,
    required this.name,
    required this.image,
    required this.unit,
    required this.price,
    required this.quantity,
    this.photo,
  });
  final String productId, name, image, unit;
  final int price, quantity;
  final Uint8List? photo;
  int get total => price * quantity;
}

class HarvestOrder {
  HarvestOrder({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.farmId,
    required this.farmName,
    required this.date,
    required this.items,
    required this.address,
    this.status = OrderStatus.pending,
    this.phone = '',
    this.note = '',
    this.payment = PaymentMethod.cashOnDelivery,
  });
  final String id, customerId, customerName, farmId, farmName, address;
  final String phone, note;
  final PaymentMethod payment;
  final DateTime date;
  final List<OrderLine> items;
  OrderStatus status;
  int get total => items.fold(0, (sum, item) => sum + item.total);
}

enum PaymentMethod { cashOnDelivery }

extension PaymentMethodName on PaymentMethod {
  String get label => switch (this) {
    PaymentMethod.cashOnDelivery => 'Cash on Delivery',
  };
  static PaymentMethod parse(Object? value) => PaymentMethod.values.firstWhere(
    (p) => p.name == value,
    orElse: () => PaymentMethod.cashOnDelivery,
  );
}

/// Details the customer fills in on the checkout form.
class CheckoutDetails {
  const CheckoutDetails({
    required this.name,
    required this.phone,
    required this.address,
    this.note = '',
    this.payment = PaymentMethod.cashOnDelivery,
  });
  final String name, phone, address, note;
  final PaymentMethod payment;
}

/// Optional SRS modules stay disabled until their service adapters exist.
class FeatureCapabilities {
  const FeatureCapabilities({
    this.pickup = false,
    this.notifications = false,
    this.following = false,
  });
  final bool pickup, notifications, following;
}

String money(int minorUnits) =>
    'Rs ${(minorUnits / 100).toStringAsFixed(minorUnits % 100 == 0 ? 0 : 2)}';
String dateLabel(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

/// Bundled product photo (assets/images/p_*.jpg) matching a product name, used
/// when a product has no uploaded image. Returns '' when nothing matches.
String stockPhotoFor(String name) {
  const keywords = {
    'tomato': 'tomato',
    'avocado': 'avocado',
    'carrot': 'carrot',
    'strawberr': 'strawberry',
    'milk': 'milk',
    'wheat': 'wheat',
    'atta': 'wheat',
    'basil': 'basil',
    'lentil': 'lentil',
    'masoor': 'lentil',
    'cucumber': 'cucumber',
    'kheera': 'cucumber',
    'potato': 'potato',
    'aloo': 'potato',
    'apple': 'apple',
    'seb': 'apple',
    'banana': 'banana',
    'kela': 'banana',
    'yogurt': 'yogurt',
    'yoghurt': 'yogurt',
    'dahi': 'yogurt',
    'butter': 'butter',
    'makhan': 'butter',
    'paneer': 'paneer',
    'rice': 'rice',
    'chawal': 'rice',
    'oat': 'oats',
    'corn': 'corn',
    'makai': 'corn',
    'mint': 'mint',
    'pudina': 'mint',
    'coriander': 'coriander',
    'dhania': 'coriander',
    'cilantro': 'coriander',
    'rosemary': 'rosemary',
    'chickpea': 'chickpea',
    'chana': 'chickpea',
    'kidney': 'kidneybean',
    'rajma': 'kidneybean',
    'mung': 'mung',
    'moong': 'mung',
  };
  final n = name.toLowerCase();
  for (final e in keywords.entries) {
    if (n.contains(e.key)) return 'p_${e.value}';
  }
  return '';
}
