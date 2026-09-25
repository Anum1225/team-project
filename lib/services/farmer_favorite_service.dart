import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/farmer_model.dart';

/// Customer Favorite/Followed Farmers Service for HarvestHub.
/// Manages followed farmers at: users/{customerUid}/favoriteFarmers/{farmerId}
class FarmerFavoriteService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  FarmerFavoriteService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  String _requireCurrentUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException(
        'You must be logged in as a customer to favorite or follow a farmer.',
        code: 'not-authenticated',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _favoriteFarmersRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('favoriteFarmers');

  CollectionReference<Map<String, dynamic>> get _farmersRef =>
      _firestore.collection('farmers');

  /// Follow/favorite a farmer.
  Future<void> followFarmer(
    String farmerId, {
    String? businessName,
    String? farmerName,
  }) async {
    final uid = _requireCurrentUserId();
    final cleanId = farmerId.trim();

    if (cleanId.isEmpty) {
      throw const FavoriteException('Farmer ID is required.', code: 'invalid-id');
    }

    try {
      // If name not provided, attempt to fetch from farmers collection
      String resolvedName = businessName ?? farmerName ?? '';
      double resolvedRating = 0.0;
      String description = '';

      if (resolvedName.isEmpty) {
        final farmerDoc = await _farmersRef.doc(cleanId).get();
        if (farmerDoc.exists) {
          final data = farmerDoc.data() ?? {};
          resolvedName = (data['businessName'] ?? data['Business_Name'] ?? data['name'] ?? 'Local Farmer').toString();
          description = (data['description'] ?? data['Description'] ?? '').toString();
          resolvedRating = (data['rating'] ?? data['Rating'] ?? 0.0) is num
              ? (data['rating'] ?? data['Rating'] ?? 0.0).toDouble()
              : 0.0;
        } else {
          resolvedName = 'Farmer $cleanId';
        }
      }

      final farmer = FarmerModel(
        farmerId: cleanId,
        businessName: resolvedName,
        description: description,
        rating: resolvedRating,
        followedAt: DateTime.now(),
      );

      await _favoriteFarmersRef(uid).doc(cleanId).set(farmer.toMap());
    } on FirebaseException catch (e) {
      throw FavoriteException('Failed to follow farmer: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw FavoriteException('Unexpected error following farmer: $e');
    }
  }

  /// Unfollow/unfavorite a farmer.
  Future<void> unfollowFarmer(String farmerId) async {
    final uid = _requireCurrentUserId();
    final cleanId = farmerId.trim();
    if (cleanId.isEmpty) return;

    try {
      await _favoriteFarmersRef(uid).doc(cleanId).delete();
    } on FirebaseException catch (e) {
      throw FavoriteException('Failed to unfollow farmer: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw FavoriteException('Unexpected error unfollowing farmer: $e');
    }
  }

  /// Check whether a farmer is followed by the current customer.
  Future<bool> isFarmerFavorite(String farmerId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final cleanId = farmerId.trim();
    if (cleanId.isEmpty) return false;

    try {
      final doc = await _favoriteFarmersRef(uid).doc(cleanId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Retrieve list of all followed/favorite farmers for the current customer.
  Future<List<FarmerModel>> getFavoriteFarmers() async {
    final uid = _requireCurrentUserId();

    try {
      final snapshot = await _favoriteFarmersRef(uid).orderBy('followedAt', descending: true).get();
      return snapshot.docs
          .map((doc) => FarmerModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      // In case followedAt index is pending, fallback to unsorted get
      try {
        final fallback = await _favoriteFarmersRef(uid).get();
        return fallback.docs
            .map((doc) => FarmerModel.fromFirestore(doc))
            .toList();
      } catch (_) {
        throw FavoriteException('Failed to get followed farmers: ${e.message}', code: e.code);
      }
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw FavoriteException('Unexpected error fetching followed farmers: $e');
    }
  }

  /// Real-time stream of followed farmers.
  Stream<List<FarmerModel>> favoriteFarmersStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _favoriteFarmersRef(uid).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => FarmerModel.fromFirestore(doc))
          .toList();
    });
  }
}
