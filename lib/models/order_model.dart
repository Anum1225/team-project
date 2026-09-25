import 'package:cloud_firestore/cloud_firestore.dart';

/// Single item within a placed order.
class OrderItemModel {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String farmerId;

  const OrderItemModel({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.farmerId = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'subtotal': subtotal,
      'farmerId': farmerId,
    };
  }

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 1;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 1;
    }

    final qty = parseInt(map['quantity']);
    final price = parseDouble(map['unitPrice'] ?? map['pricePerUnit']);
    final sub = map['subtotal'] != null ? parseDouble(map['subtotal']) : (qty * price);

    return OrderItemModel(
      productId: (map['productId'] ?? '').toString(),
      productName: (map['productName'] ?? map['itemName'] ?? '').toString(),
      quantity: qty,
      unitPrice: price,
      subtotal: sub,
      farmerId: (map['farmerId'] ?? '').toString(),
    );
  }
}

/// Order model for HarvestHub Customer Orders.
/// Based on SRS Orders Collection:
/// - Order_Id (PK)
/// - Customer_Id (FK)
/// - Farmer_Id (FK)
/// - Items_JSON (or items list)
/// - Pickup_Slot_Time
/// - Status (Pending, Confirmed, Ready for Pickup, Completed, Cancelled)
/// - Total_Price
/// - Created_At
class OrderModel {
  static const String statusPending = 'Pending';
  static const String statusConfirmed = 'Confirmed';
  static const String statusReadyForPickup = 'Ready for Pickup';
  static const String statusCompleted = 'Completed';
  static const String statusCancelled = 'Cancelled';

  final String orderId;
  final String customerId;
  final String farmerId;
  final List<OrderItemModel> items;
  final double totalPrice;
  final String status;
  final DateTime createdAt;
  final String deliveryAddress;
  final String? pickupSlotTime;

  const OrderModel({
    required this.orderId,
    required this.customerId,
    this.farmerId = '',
    required this.items,
    required this.totalPrice,
    this.status = statusPending,
    required this.createdAt,
    this.deliveryAddress = '',
    this.pickupSlotTime,
  });

  /// Check whether order is still in Pending status.
  bool get isPending => status == statusPending;

  /// Check whether order is cancelled.
  bool get isCancelled => status == statusCancelled;

  /// Total count of individual items ordered.
  int get totalItemCount => items.fold(0, (total, item) => total + item.quantity);

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'customerId': customerId,
      'farmerId': farmerId,
      'items': items.map((i) => i.toMap()).toList(),
      'totalPrice': totalPrice,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'deliveryAddress': deliveryAddress,
      'pickupSlotTime': pickupSlotTime,
      // SRS compatibility keys
      'Order_Id': orderId,
      'Customer_Id': customerId,
      'Farmer_Id': farmerId,
      'Status': status,
      'Total_Price': totalPrice,
      'Pickup_Slot_Time': pickupSlotTime,
      'Created_At': Timestamp.fromDate(createdAt),
    };
  }

  /// Construct from Map.
  factory OrderModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString()) ?? 0.0;
    }

    final rawItems = map['items'] ?? map['Items_JSON'];
    final List<OrderItemModel> parsedItems = [];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map<String, dynamic>) {
          parsedItems.add(OrderItemModel.fromMap(item));
        } else if (item is Map) {
          parsedItems.add(OrderItemModel.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }

    return OrderModel(
      orderId: (map['orderId'] ?? map['Order_Id'] ?? documentId ?? '').toString(),
      customerId: (map['customerId'] ?? map['Customer_Id'] ?? '').toString(),
      farmerId: (map['farmerId'] ?? map['Farmer_Id'] ?? '').toString(),
      items: parsedItems,
      totalPrice: parseDouble(map['totalPrice'] ?? map['Total_Price']),
      status: (map['status'] ?? map['Status'] ?? statusPending).toString(),
      createdAt: parseDate(map['createdAt'] ?? map['Created_At']),
      deliveryAddress: (map['deliveryAddress'] ?? map['address'] ?? '').toString(),
      pickupSlotTime: map['pickupSlotTime']?.toString() ?? map['Pickup_Slot_Time']?.toString(),
    );
  }

  /// Construct from Firestore DocumentSnapshot.
  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return OrderModel.fromMap(data, documentId: doc.id);
  }

  @override
  String toString() {
    return 'OrderModel(orderId: $orderId, total: \$$totalPrice, status: $status, items: ${items.length})';
  }
}
