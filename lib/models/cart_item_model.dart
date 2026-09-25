import 'package:cloud_firestore/cloud_firestore.dart';

/// Shopping cart item for HarvestHub Customer.
/// Stored in Firestore at: users/{uid}/cart/{productId}
class CartItemModel {
  final String productId;
  final String productName;
  final String imageUrl;
  final double pricePerUnit;
  final int quantity;
  final String farmerId;
  final DateTime addedAt;

  const CartItemModel({
    required this.productId,
    required this.productName,
    this.imageUrl = '',
    required this.pricePerUnit,
    required this.quantity,
    this.farmerId = '',
    required this.addedAt,
  });

  /// Computed subtotal for this item.
  double get subtotal => pricePerUnit * quantity;

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'imageUrl': imageUrl,
      'pricePerUnit': pricePerUnit,
      'quantity': quantity,
      'farmerId': farmerId,
      'addedAt': Timestamp.fromDate(addedAt),
    };
  }

  /// Construct CartItemModel from Map.
  factory CartItemModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 1;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 1;
      return 1;
    }

    return CartItemModel(
      productId: (map['productId'] ?? documentId ?? '').toString(),
      productName: (map['productName'] ?? map['itemName'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      pricePerUnit: parseDouble(map['pricePerUnit'] ?? map['price']),
      quantity: parseInt(map['quantity']),
      farmerId: (map['farmerId'] ?? '').toString(),
      addedAt: parseDate(map['addedAt']),
    );
  }

  /// Construct CartItemModel from Firestore DocumentSnapshot.
  factory CartItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CartItemModel.fromMap(data, documentId: doc.id);
  }

  /// Copy with updated quantity or fields.
  CartItemModel copyWith({
    String? productId,
    String? productName,
    String? imageUrl,
    double? pricePerUnit,
    int? quantity,
    String? farmerId,
    DateTime? addedAt,
  }) {
    return CartItemModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      imageUrl: imageUrl ?? this.imageUrl,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      quantity: quantity ?? this.quantity,
      farmerId: farmerId ?? this.farmerId,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  @override
  String toString() {
    return 'CartItemModel(productId: $productId, name: $productName, qty: $quantity, price: $pricePerUnit)';
  }
}
