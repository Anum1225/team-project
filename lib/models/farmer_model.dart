import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a Farmer or a Followed/Favorite Farmer from a Customer's perspective.
/// Based on SRS Farmers Collection:
/// - Farmer_Id (PK)
/// - User_Id (FK)
/// - Market_Id (FK)
/// - Business_Name
/// - Description
/// - Rating
class FarmerModel {
  final String farmerId;
  final String userId;
  final String marketId;
  final String businessName;
  final String description;
  final double rating;
  final DateTime? followedAt;

  const FarmerModel({
    required this.farmerId,
    this.userId = '',
    this.marketId = '',
    required this.businessName,
    this.description = '',
    this.rating = 0.0,
    this.followedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'userId': userId,
      'marketId': marketId,
      'businessName': businessName,
      'description': description,
      'rating': rating,
      'followedAt': followedAt != null ? Timestamp.fromDate(followedAt!) : null,
      // SRS schema compatibility
      'Farmer_Id': farmerId,
      'User_Id': userId,
      'Market_Id': marketId,
      'Business_Name': businessName,
      'Description': description,
      'Rating': rating,
    };
  }

  factory FarmerModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      return null;
    }

    return FarmerModel(
      farmerId: (map['farmerId'] ?? map['Farmer_Id'] ?? documentId ?? '').toString(),
      userId: (map['userId'] ?? map['User_Id'] ?? '').toString(),
      marketId: (map['marketId'] ?? map['Market_Id'] ?? '').toString(),
      businessName: (map['businessName'] ?? map['Business_Name'] ?? map['farmerName'] ?? map['name'] ?? '').toString(),
      description: (map['description'] ?? map['Description'] ?? '').toString(),
      rating: parseDouble(map['rating'] ?? map['Rating']),
      followedAt: parseDate(map['followedAt']),
    );
  }

  factory FarmerModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return FarmerModel.fromMap(data, documentId: doc.id);
  }

  @override
  String toString() => 'FarmerModel(id: $farmerId, business: $businessName, rating: $rating)';
}
