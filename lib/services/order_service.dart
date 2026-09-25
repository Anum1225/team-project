import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import 'cart_service.dart';
import 'user_service.dart';

/// Customer Order Service for HarvestHub.
/// Handles simulated checkout, transactional stock deduction, order placement,
/// and customer order history.
class OrderService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;
  final CartService? _customCartService;
  final UserService? _customUserService;

  OrderService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    CartService? cartService,
    UserService? userService,
  })  : _customAuth = auth,
        _customFirestore = firestore,
        _customCartService = cartService,
        _customUserService = userService;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;
  CartService get _cartService =>
      _customCartService ?? CartService(auth: _customAuth, firestore: _customFirestore);
  UserService get _userService =>
      _customUserService ?? UserService(auth: _customAuth, firestore: _customFirestore);

  String _requireCurrentUserId() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw const AuthException(
        'You must be logged in as a customer to place or view orders.',
        code: 'not-authenticated',
      );
    }
    return uid;
  }

  CollectionReference<Map<String, dynamic>> get _ordersRef =>
      _firestore.collection('orders');

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// 7. CUSTOMER ORDER CREATION (Simulated Checkout)
  ///
  /// Executes checkout within an atomic Firestore transaction:
  /// 1. Validates customer authentication.
  /// 2. Validates cart is not empty.
  /// 3. Reads latest product data directly from Firestore inside transaction.
  /// 4. Validates product availability and stock quantity.
  /// 5. Calculates order total using trusted backend prices.
  /// 6. Deducts inventory stock atomically.
  /// 7. Writes order document to orders/{orderId}.
  /// 8. Clears the customer's cart.
  ///
  /// Parameters:
  /// - [deliveryAddress]: Optional custom delivery address; defaults to customer profile address.
  /// - [pickupSlotTime]: Optional pickup slot time booking if customer selects pickup.
  Future<OrderModel> createOrder({
    String? deliveryAddress,
    String? pickupSlotTime,
  }) async {
    final uid = _requireCurrentUserId();

    // 1. Fetch customer's current cart items
    final cartItems = await _cartService.getCart();
    if (cartItems.isEmpty) {
      throw const OrderException(
        'Your shopping cart is empty. Please add products before checking out.',
        code: 'empty-cart',
      );
    }

    // 2. Resolve delivery address (parameter or profile address)
    String finalAddress = deliveryAddress?.trim() ?? '';
    if (finalAddress.isEmpty) {
      final profile = await _userService.getCustomerProfile(uid);
      finalAddress = profile?.address ?? '';
    }

    // Generate new order document reference
    final newOrderRef = _ordersRef.doc();
    final orderId = newOrderRef.id;
    final now = DateTime.now();

    try {
      // 3. Execute transactional stock check and deduction
      final createdOrder = await _firestore.runTransaction<OrderModel>((transaction) async {
        final List<OrderItemModel> verifiedItems = [];
        double calculatedTotal = 0.0;
        String primaryFarmerId = '';

        // Read all product documents first inside transaction
        final Map<String, DocumentSnapshot<Map<String, dynamic>>> productDocs = {};
        for (final cartItem in cartItems) {
          final prodDocRef = _productsRef.doc(cartItem.productId);
          final snapshot = await transaction.get(prodDocRef);
          productDocs[cartItem.productId] = snapshot;
        }

        // Validate availability and stock for each item
        for (final cartItem in cartItems) {
          final snapshot = productDocs[cartItem.productId]!;

          if (!snapshot.exists) {
            throw OrderException(
              'Product "${cartItem.productName}" is no longer available.',
              code: 'product-not-found',
            );
          }

          final product = ProductModel.fromFirestore(snapshot);

          if (product.stockQty < cartItem.quantity) {
            throw OrderException(
              'Insufficient stock for "${product.itemName}". Only ${product.stockQty} ${product.unit} remaining in stock.',
              code: 'insufficient-stock',
            );
          }

          final itemSubtotal = product.pricePerUnit * cartItem.quantity;
          calculatedTotal += itemSubtotal;

          if (primaryFarmerId.isEmpty && product.farmerId.isNotEmpty) {
            primaryFarmerId = product.farmerId;
          }

          verifiedItems.add(OrderItemModel(
            productId: product.productId,
            productName: product.itemName,
            quantity: cartItem.quantity,
            unitPrice: product.pricePerUnit, // Trusted price from database
            subtotal: itemSubtotal,
            farmerId: product.farmerId,
          ));

          // Atomically deduct product stock
          final newStock = product.stockQty - cartItem.quantity;
          transaction.update(snapshot.reference, {
            'stockQty': newStock,
            'Stock_Qty': newStock,
          });
        }

        // Create the order model
        final order = OrderModel(
          orderId: orderId,
          customerId: uid,
          farmerId: primaryFarmerId,
          items: verifiedItems,
          totalPrice: double.parse(calculatedTotal.toStringAsFixed(2)),
          status: OrderModel.statusPending,
          createdAt: now,
          deliveryAddress: finalAddress,
          pickupSlotTime: pickupSlotTime,
        );

        // Write order document inside transaction
        transaction.set(newOrderRef, order.toMap());

        return order;
      });

      // 4. Clear the customer's cart after successful order creation
      await _cartService.clearCart();

      return createdOrder;
    } on FirebaseException catch (e) {
      throw OrderException('Failed to place order: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw OrderException('Unexpected error creating order: $e');
    }
  }

  /// 8. ORDER HISTORY
  ///
  /// Retrieves all orders placed by the currently authenticated customer.
  /// Strictly filters by `customerId == currentUserId` to prevent cross-customer access.
  Future<List<OrderModel>> getCustomerOrders() async {
    final uid = _requireCurrentUserId();

    try {
      final snapshot = await _ordersRef
          .where('customerId', isEqualTo: uid)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      // In case composite index on customerId + createdAt is pending, fallback to in-memory sort
      try {
        final fallbackSnapshot = await _ordersRef
            .where('customerId', isEqualTo: uid)
            .get();

        final list = fallbackSnapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList();
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        return list;
      } catch (_) {
        throw OrderException('Failed to retrieve order history: ${e.message}', code: e.code);
      }
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw OrderException('Unexpected error fetching orders: $e');
    }
  }

  /// Real-time stream of the customer's orders.
  Stream<List<OrderModel>> customerOrdersStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      return Stream.value([]);
    }

    return _ordersRef
        .where('customerId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => OrderModel.fromFirestore(doc))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  /// Retrieve a specific order by [orderId].
  /// Enforces ownership check: customers can only view their own orders.
  Future<OrderModel?> getOrderById(String orderId) async {
    final uid = _requireCurrentUserId();
    final cleanId = orderId.trim();
    if (cleanId.isEmpty) return null;

    try {
      final doc = await _ordersRef.doc(cleanId).get();
      if (!doc.exists) return null;

      final order = OrderModel.fromFirestore(doc);

      // Ownership enforcement
      if (order.customerId != uid) {
        throw const OrderException(
          'Unauthorized: You do not have permission to view this order.',
          code: 'unauthorized',
        );
      }

      return order;
    } on FirebaseException catch (e) {
      throw OrderException('Failed to load order: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw OrderException('Unexpected error loading order: $e');
    }
  }

  /// Cancel an order if it is still in "Pending" status and restock the products.
  Future<void> cancelOrder(String orderId) async {
    final uid = _requireCurrentUserId();
    final cleanId = orderId.trim();

    try {
      await _firestore.runTransaction((transaction) async {
        final orderDocRef = _ordersRef.doc(cleanId);
        final snapshot = await transaction.get(orderDocRef);

        if (!snapshot.exists) {
          throw const OrderException('Order not found.', code: 'not-found');
        }

        final order = OrderModel.fromFirestore(snapshot);

        if (order.customerId != uid) {
          throw const OrderException('Unauthorized to cancel this order.', code: 'unauthorized');
        }

        if (order.status != OrderModel.statusPending) {
          throw OrderException(
            'Cannot cancel an order with status "${order.status}". Only Pending orders can be cancelled.',
            code: 'invalid-status',
          );
        }

        // Restock products
        for (final item in order.items) {
          final prodRef = _productsRef.doc(item.productId);
          final prodSnap = await transaction.get(prodRef);
          if (prodSnap.exists) {
            final currentStock = (prodSnap.data()?['stockQty'] ?? prodSnap.data()?['Stock_Qty'] ?? 0) as num;
            final newStock = currentStock.toInt() + item.quantity;
            transaction.update(prodRef, {
              'stockQty': newStock,
              'Stock_Qty': newStock,
            });
          }
        }

        // Update status to Cancelled
        transaction.update(orderDocRef, {
          'status': OrderModel.statusCancelled,
          'Status': OrderModel.statusCancelled,
        });
      });
    } on FirebaseException catch (e) {
      throw OrderException('Failed to cancel order: ${e.message}', code: e.code);
    } catch (e) {
      if (e is HarvestHubException) rethrow;
      throw OrderException('Unexpected error cancelling order: $e');
    }
  }
}
