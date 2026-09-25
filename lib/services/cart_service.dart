import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/cart_item_model.dart';
import 'product_service.dart';

/// Customer Shopping Cart Service for HarvestHub.
/// Manages cart items at: users/{uid}/cart/{productId}
class CartService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final ProductService? _customProductService;

  CartService({
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
        'You must be logged in as a customer to manage your cart.',
        code: 'not-authenticated',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> _cartRef(String uid) =>
      _firestore.collection('users').doc(uid).collection('cart');

  /// Add a product to the cart with trusted stock and price verification.
  ///
  /// Requirements:
  /// - Quantity must be > 0
  /// - Product must exist in Firestore
  /// - Cannot order product with zero stock
  /// - Cannot order more than available stock
  Future<void> addToCart(String productId, {int quantity = 1}) async {
    final uid = _requireCurrentUserId();
    final cleanId = productId.trim();

    if (cleanId.isEmpty) {
      throw const CartException('Product ID is required.', code: 'invalid-id');
    }
    if (quantity <= 0) {
      throw const CartException('Quantity must be greater than zero.', code: 'invalid-quantity');
    }

    // 1. Fetch current product information from Firestore (do NOT trust client)
    final product = await _productService.getProductById(cleanId);
    if (product == null) {
      throw const CartException('Product not found or no longer available.', code: 'product-not-found');
    }

    if (product.isOutOfStock) {
      throw CartException(
        'Sorry, "${product.itemName}" is currently out of stock.',
        code: 'out-of-stock',
      );
    }

    // 2. Check if product is already in cart
    final cartDoc = await _cartRef(uid).doc(cleanId).get();
    int newQuantity = quantity;

    if (cartDoc.exists) {
      final existingItem = CartItemModel.fromFirestore(cartDoc);
      newQuantity = existingItem.quantity + quantity;
    }

    // 3. Validate against available stock
    if (newQuantity > product.stockQty) {
      throw CartException(
        'Cannot add $quantity more. Available stock for "${product.itemName}" is ${product.stockQty} ${product.unit} (you currently have ${cartDoc.exists ? (cartDoc.data()?['quantity'] ?? 0) : 0} in cart).',
        code: 'insufficient-stock',
      );
    }

    // 4. Save to Firestore
    final cartItem = CartItemModel(
      productId: product.productId,
      productName: product.itemName,
      imageUrl: product.imageUrl,
      pricePerUnit: product.pricePerUnit,
      quantity: newQuantity,
      farmerId: product.farmerId,
      addedAt: DateTime.now(),
    );

    try {
      await _cartRef(uid).doc(cleanId).set(cartItem.toMap());
    } on FirebaseException catch (e) {
      throw CartException('Failed to update cart: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw CartException('Unexpected error adding to cart: $e');
    }
  }

  /// Update the quantity of a specific cart item.
  /// If [newQuantity] <= 0, the item is removed from the cart.
  Future<void> updateCartQuantity(String productId, int newQuantity) async {
    final uid = _requireCurrentUserId();
    final cleanId = productId.trim();

    if (cleanId.isEmpty) return;

    if (newQuantity <= 0) {
      await removeFromCart(cleanId);
      return;
    }

    // Verify stock before updating
    final product = await _productService.getProductById(cleanId);
    if (product == null) {
      await removeFromCart(cleanId);
      throw const CartException('Product no longer exists. Removed from cart.', code: 'product-not-found');
    }

    if (newQuantity > product.stockQty) {
      throw CartException(
        'Cannot set quantity to $newQuantity. Only ${product.stockQty} ${product.unit} available.',
        code: 'insufficient-stock',
      );
    }

    try {
      await _cartRef(uid).doc(cleanId).update({
        'quantity': newQuantity,
        'pricePerUnit': product.pricePerUnit, // Keep price refreshed
      });
    } on FirebaseException catch (e) {
      throw CartException('Failed to update quantity: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw CartException('Unexpected error updating cart: $e');
    }
  }

  /// Remove a product from the shopping cart.
  Future<void> removeFromCart(String productId) async {
    final uid = _requireCurrentUserId();
    final cleanId = productId.trim();
    if (cleanId.isEmpty) return;

    try {
      await _cartRef(uid).doc(cleanId).delete();
    } on FirebaseException catch (e) {
      throw CartException('Failed to remove item: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw CartException('Unexpected error removing from cart: $e');
    }
  }

  /// Retrieve all current cart items for the logged-in customer.
  Future<List<CartItemModel>> getCart() async {
    final uid = _requireCurrentUserId();

    try {
      final snapshot = await _cartRef(uid).orderBy('addedAt', descending: false).get();
      return snapshot.docs
          .map((doc) => CartItemModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw CartException('Failed to load cart: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw CartException('Unexpected error loading cart: $e');
    }
  }

  /// Real-time stream of shopping cart items.
  Stream<List<CartItemModel>> cartStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _cartRef(uid)
        .orderBy('addedAt', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => CartItemModel.fromFirestore(doc))
          .toList();
    });
  }

  /// Clear all items from the customer's shopping cart.
  Future<void> clearCart() async {
    final uid = _requireCurrentUserId();

    try {
      final snapshot = await _cartRef(uid).get();
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } on FirebaseException catch (e) {
      throw CartException('Failed to clear cart: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw CartException('Unexpected error clearing cart: $e');
    }
  }

  /// Calculate the subtotal of the current shopping cart.
  Future<double> calculateSubtotal() async {
    final items = await getCart();
    return items.fold<double>(0.0, (total, item) => total + item.subtotal);
  }

  /// Get the total count of items in the cart.
  Future<int> getCartItemCount() async {
    final items = await getCart();
    return items.fold<int>(0, (total, item) => total + item.quantity);
  }
}
