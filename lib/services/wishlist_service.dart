import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/product_model.dart';
import '../models/wishlist_item_model.dart';
import 'product_service.dart';

/// Customer Wishlist Service for HarvestHub.
/// Manages customer wishlist items at: users/{uid}/wishlist/{productId}
class WishlistService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final ProductService? _customProductService;

  WishlistService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    ProductService? productService,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customProductService = productService;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  ProductService get _productService =>
      _customProductService ?? ProductService(firestore: _customFirestore);

  String _requireCurrentUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException(
        'You must be logged in as a customer to manage your wishlist.',
        code: 'not-authenticated',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _wishlistRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('wishlist');

  /// Add a product to the customer's wishlist.
  /// If optional [product] is passed, basic metadata is cached for fast listing.
  Future<void> addToWishlist(String productId, {ProductModel? product}) async {
    final uid = _requireCurrentUserId();
    final cleanId = productId.trim();
    if (cleanId.isEmpty) {
      throw const WishlistException('Product ID cannot be empty.', code: 'invalid-id');
    }

    try {
      // If product details not passed, optionally fetch to cache item metadata
      ProductModel? prod = product;
      prod ??= await _productService.getProductById(cleanId);

      final wishlistItem = WishlistItemModel(
        productId: cleanId,
        addedAt: DateTime.now(),
        productName: prod?.itemName ?? '',
        imageUrl: prod?.imageUrl ?? '',
        pricePerUnit: prod?.pricePerUnit ?? 0.0,
        category: prod?.category ?? '',
        farmerId: prod?.farmerId ?? '',
      );

      await _wishlistRef(uid).doc(cleanId).set(wishlistItem.toMap());
    } on FirebaseException catch (e) {
      throw WishlistException('Failed to add to wishlist: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw WishlistException('Unexpected error adding to wishlist: $e');
    }
  }

  /// Remove a product from the customer's wishlist.
  Future<void> removeFromWishlist(String productId) async {
    final uid = _requireCurrentUserId();
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return;

    try {
      await _wishlistRef(uid).doc(cleanId).delete();
    } on FirebaseException catch (e) {
      throw WishlistException('Failed to remove from wishlist: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw WishlistException('Unexpected error removing from wishlist: $e');
    }
  }

  /// Check whether a product is currently in the customer's wishlist.
  Future<bool> isProductInWishlist(String productId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return false;

    try {
      final doc = await _wishlistRef(uid).doc(cleanId).get();
      return doc.exists;
    } catch (_) {
      return false;
    }
  }

  /// Get list of all wishlist items for the authenticated customer.
  Future<List<WishlistItemModel>> getWishlist() async {
    final uid = _requireCurrentUserId();

    try {
      final snapshot = await _wishlistRef(uid).orderBy('addedAt', descending: true).get();
      return snapshot.docs
          .map((doc) => WishlistItemModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw WishlistException('Failed to retrieve wishlist: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw WishlistException('Unexpected error getting wishlist: $e');
    }
  }

  /// Real-time stream of customer's wishlist items.
  Stream<List<WishlistItemModel>> wishlistStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _wishlistRef(uid)
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => WishlistItemModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Get the actual [ProductModel]s for items in the wishlist.
  Future<List<ProductModel>> getWishlistProducts() async {
    final items = await getWishlist();
    final List<ProductModel> products = [];

    for (final item in items) {
      final prod = await _productService.getProductById(item.productId);
      if (prod != null) {
        products.add(prod);
      }
    }
    return products;
  }
}
