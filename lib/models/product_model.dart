import 'package:cloud_firestore/cloud_firestore.dart';

/// Product model representing an agricultural item in HarvestHub.
/// Based on SRS Products Collection:
/// - Product_Id (PK)
/// - Farmer_Id (FK)
/// - Item_Name
/// - Category
/// - Price_Per_Unit
/// - Stock_Qty
/// - Image_Url
/// - Description
class ProductModel {
  final String productId;
  final String farmerId;
  final String itemName;
  final String category;
  final double pricePerUnit;
  final int stockQty;
  final String imageUrl;
  final String description;
  final String? farmerName;
  final String unit; // e.g. "kg", "dozen", "pack", "bundle"

  const ProductModel({
    required this.productId,
    required this.farmerId,
    required this.itemName,
    required this.category,
    required this.pricePerUnit,
    required this.stockQty,
    this.imageUrl = '',
    this.description = '',
    this.farmerName,
    this.unit = 'kg',
  });

  /// Check whether product is in stock.
  bool get isInStock => stockQty > 0;

  /// Check whether product is out of stock.
  bool get isOutOfStock => stockQty <= 0;

  /// Convert to Map.
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'farmerId': farmerId,
      'itemName': itemName,
      'category': category,
      'pricePerUnit': pricePerUnit,
      'stockQty': stockQty,
      'imageUrl': imageUrl,
      'description': description,
      'farmerName': farmerName,
      'unit': unit,
      // SRS schema compatibility
      'Product_Id': productId,
      'Farmer_Id': farmerId,
      'Item_Name': itemName,
      'Category': category,
      'Price_Per_Unit': pricePerUnit,
      'Stock_Qty': stockQty,
      'Image_Url': imageUrl,
    };
  }

  /// Construct ProductModel from Map.
  factory ProductModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is num) return value.toDouble();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9.]'), '');
        return double.tryParse(cleaned) ?? 0.0;
      }
      return 0.0;
    }

    int parseInt(dynamic value) {
      if (value == null) return 0;
      if (value is num) return value.toInt();
      if (value is String) {
        final cleaned = value.replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(cleaned) ?? 0;
      }
      return 0;
    }

    return ProductModel(
      productId: (map['productId'] ?? map['Product_Id'] ?? map['id'] ?? documentId ?? '').toString(),
      farmerId: (map['farmerId'] ?? map['Farmer_Id'] ?? '').toString(),
      itemName: (map['itemName'] ?? map['Item_Name'] ?? map['name'] ?? '').toString(),
      category: (map['category'] ?? map['Category'] ?? '').toString(),
      pricePerUnit: parseDouble(map['pricePerUnit'] ?? map['Price_Per_Unit'] ?? map['pricePerKg'] ?? map['price']),
      stockQty: parseInt(map['stockQty'] ?? map['Stock_Qty'] ?? map['quantity']),
      imageUrl: (map['imageUrl'] ?? map['Image_Url'] ?? '').toString(),
      description: (map['description'] ?? map['Description'] ?? '').toString(),
      farmerName: map['farmerName']?.toString() ?? map['Farmer_Name']?.toString(),
      unit: (map['unit'] ?? 'kg').toString(),
    );
  }

  /// Construct ProductModel from Firestore DocumentSnapshot.
  factory ProductModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ProductModel.fromMap(data, documentId: doc.id);
  }

  /// Copy with updated fields.
  ProductModel copyWith({
    String? productId,
    String? farmerId,
    String? itemName,
    String? category,
    double? pricePerUnit,
    int? stockQty,
    String? imageUrl,
    String? description,
    String? farmerName,
    String? unit,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      farmerId: farmerId ?? this.farmerId,
      itemName: itemName ?? this.itemName,
      category: category ?? this.category,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      stockQty: stockQty ?? this.stockQty,
      imageUrl: imageUrl ?? this.imageUrl,
      description: description ?? this.description,
      farmerName: farmerName ?? this.farmerName,
      unit: unit ?? this.unit,
    );
  }

  @override
  String toString() {
    return 'ProductModel(id: $productId, name: $itemName, price: $pricePerUnit, stock: $stockQty)';
  }
}
