import 'package:cloud_firestore/cloud_firestore.dart';

/// Customer/User model representing a registered user in HarvestHub.
/// Compatible with Firestore users/{uid} document.
class UserModel {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String address;
  final String role;
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    this.role = 'Customer',
    required this.createdAt,
  });

  /// True if this user has the Customer role.
  bool get isCustomer => role.toLowerCase() == 'customer';

  /// Convert user model to Firestore map.
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      // Also store SRS schema compatible keys
      'User_Id': userId,
      'Role': role,
      'Created_At': Timestamp.fromDate(createdAt),
    };
  }

  /// Construct a UserModel from a Map and optional document ID.
  factory UserModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    return UserModel(
      userId: (map['userId'] ?? map['User_Id'] ?? documentId ?? '').toString(),
      name: (map['name'] ?? map['Name'] ?? '').toString(),
      email: (map['email'] ?? map['Email'] ?? '').toString(),
      phone: (map['phone'] ?? map['Phone'] ?? map['mobilePhone'] ?? '').toString(),
      address: (map['address'] ?? map['Address'] ?? '').toString(),
      role: (map['role'] ?? map['Role'] ?? 'Customer').toString(),
      createdAt: parseDate(map['createdAt'] ?? map['Created_At']),
    );
  }

  /// Construct a UserModel from a Firestore DocumentSnapshot.
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserModel.fromMap(data, documentId: doc.id);
  }

  /// Create a copy of this UserModel with updated fields.
  UserModel copyWith({
    String? userId,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? role,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'UserModel(userId: $userId, name: $name, email: $email, role: $role)';
  }
}
