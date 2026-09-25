import 'package:cloud_firestore/cloud_firestore.dart';
import '../exceptions/app_exceptions.dart';
import '../models/product_model.dart';
import '../dummy_data.dart';

/// Customer Product Service for HarvestHub.
/// Provides read-only operations for browsing, searching, and filtering available farm products.
class ProductService {
  final FirebaseFirestore? _customFirestore;

  ProductService({
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _firestore.collection('products');

  /// Get all available products from Firestore.
  /// If [inStockOnly] is true, only products with stockQty > 0 are returned.
  /// If Firestore collection is empty, returns items converted from [HarvestHubDummyData.dummyCrops]
  /// to ensure the existing app UI remains interactive during testing.
  Future<List<ProductModel>> getAllProducts({bool inStockOnly = false}) async {
    try {
      final snapshot = await _productsRef.get();

      if (snapshot.docs.isEmpty) {
        // Fallback to dummy crops if Firestore has not been seeded yet
        final fallback = HarvestHubDummyData.dummyCrops
            .map((crop) => ProductModel.fromMap(crop))
            .toList();
        if (inStockOnly) {
          return fallback.where((p) => p.isInStock).toList();
        }
        return fallback;
      }

      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();

      if (inStockOnly) {
        return products.where((p) => p.isInStock).toList();
      }
      return products;
    } on FirebaseException catch (e) {
      throw ProductException('Failed to load products: ${e.message}', code: e.code);
    } catch (e) {
      throw ProductException('Unexpected error fetching products: $e');
    }
  }

  /// Real-time stream of all products.
  Stream<List<ProductModel>> productsStream({bool inStockOnly = false}) {
    return _productsRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        final fallback = HarvestHubDummyData.dummyCrops
            .map((crop) => ProductModel.fromMap(crop))
            .toList();
        return inStockOnly ? fallback.where((p) => p.isInStock).toList() : fallback;
      }
      final products = snapshot.docs
          .map((doc) => ProductModel.fromFirestore(doc))
          .toList();
      return inStockOnly ? products.where((p) => p.isInStock).toList() : products;
    });
  }

  /// Retrieve a specific product by its unique [productId].
  Future<ProductModel?> getProductById(String productId) async {
    final trimmedId = productId.trim();
    if (trimmedId.isEmpty) return null;

    try {
      final doc = await _productsRef.doc(trimmedId).get();
      if (doc.exists) {
        return ProductModel.fromFirestore(doc);
      }

      // Check fallback dummy data
      try {
        final match = HarvestHubDummyData.dummyCrops.firstWhere(
          (c) => c['id'] == trimmedId,
        );
        return ProductModel.fromMap(match);
      } catch (_) {
        return null;
      }
    } on FirebaseException catch (e) {
      throw ProductException('Error fetching product: ${e.message}', code: e.code);
    } catch (e) {
      throw ProductException('Unexpected error retrieving product: $e');
    }
  }

  /// Search products by keyword/name (case-insensitive).
  Future<List<ProductModel>> searchProducts(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      return getAllProducts();
    }

    final all = await getAllProducts();
    return all.where((product) {
      final nameMatches = product.itemName.toLowerCase().contains(cleanQuery);
      final categoryMatches = product.category.toLowerCase().contains(cleanQuery);
      final descriptionMatches = product.description.toLowerCase().contains(cleanQuery);
      final farmerMatches = product.farmerName?.toLowerCase().contains(cleanQuery) ?? false;
      return nameMatches || categoryMatches || descriptionMatches || farmerMatches;
    }).toList();
  }

  /// Filter products by specific agricultural category.
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    final cleanCat = category.trim().toLowerCase();
    if (cleanCat.isEmpty || cleanCat == 'all') {
      return getAllProducts();
    }

    final all = await getAllProducts();
    return all.where((p) => p.category.toLowerCase() == cleanCat).toList();
  }

  /// Filter products by specific farmer ID.
  Future<List<ProductModel>> getProductsByFarmer(String farmerId) async {
    final trimmedId = farmerId.trim();
    if (trimmedId.isEmpty) return [];

    final all = await getAllProducts();
    return all.where((p) => p.farmerId == trimmedId).toList();
  }

  /// Advanced product filtering supporting category, farmer, price range, stock, and search query.
  Future<List<ProductModel>> filterProducts({
    String? category,
    String? farmerId,
    double? minPrice,
    double? maxPrice,
    bool inStockOnly = false,
    String? searchQuery,
  }) async {
    var list = await getAllProducts(inStockOnly: inStockOnly);

    if (category != null && category.trim().isNotEmpty && category.trim().toLowerCase() != 'all') {
      final cat = category.trim().toLowerCase();
      list = list.where((p) => p.category.toLowerCase() == cat).toList();
    }

    if (farmerId != null && farmerId.trim().isNotEmpty) {
      final fId = farmerId.trim();
      list = list.where((p) => p.farmerId == fId).toList();
    }

    if (minPrice != null) {
      list = list.where((p) => p.pricePerUnit >= minPrice).toList();
    }

    if (maxPrice != null) {
      list = list.where((p) => p.pricePerUnit <= maxPrice).toList();
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final q = searchQuery.trim().toLowerCase();
      list = list.where((p) {
        return p.itemName.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q) ||
            p.description.toLowerCase().contains(q) ||
            (p.farmerName?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return list;
  }
}
