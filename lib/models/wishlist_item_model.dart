import 'package:cloud_firestore/cloud_firestore.dart';

/// Wishlist item model for HarvestHub Customer.
/// Stored in Firestore at: users/{uid}/wishlist/{productId}
class WishlistItemModel {
  final String productId;
  final DateTime addedAt;
  final String productName;
  final String imageUrl;
  final double pricePerUnit;
  final String category;
  final String farmerId;

  const WishlistItemModel({
    required this.productId,
    required this.addedAt,
    this.productName = '',
    this.imageUrl = '',
    this.pricePerUnit = 0.0,
    this.category = '',
    this.farmerId = '',
  });

  /// Convert to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'addedAt': Timestamp.fromDate(addedAt),
      'productName': productName,
      'imageUrl': imageUrl,
      'pricePerUnit': pricePerUnit,
      'category': category,
      'farmerId': farmerId,
    };
  }

  /// Construct from Map.
  factory WishlistItemModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
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

    return WishlistItemModel(
      productId: (map['productId'] ?? documentId ?? '').toString(),
      addedAt: parseDate(map['addedAt']),
      productName: (map['productName'] ?? map['itemName'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
      pricePerUnit: parseDouble(map['pricePerUnit'] ?? map['price']),
      category: (map['category'] ?? '').toString(),
      farmerId: (map['farmerId'] ?? '').toString(),
    );
  }

  /// Construct from Firestore DocumentSnapshot.
  factory WishlistItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WishlistItemModel.fromMap(data, documentId: doc.id);
  }

  @override
  String toString() {
    return 'WishlistItemModel(productId: $productId, name: $productName, addedAt: $addedAt)';
  }
}
