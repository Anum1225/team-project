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
  });
  final String id, owner;
  String name, location, market, description, image;
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
  });
  final String id, customerId, customerName, farmId, farmName, address;
  final DateTime date;
  final List<OrderLine> items;
  OrderStatus status;
  int get total => items.fold(0, (sum, item) => sum + item.total);
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
