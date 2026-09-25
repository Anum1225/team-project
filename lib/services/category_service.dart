import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/category_model.dart';

/// Customer Category Service for HarvestHub.
/// Provides read-only access to product categories for filtering and browsing.
class CategoryService {
  final FirebaseFirestore? _customFirestore;

  CategoryService({
    FirebaseFirestore? firestore,
  }) : _customFirestore = firestore;

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');

  /// Retrieve all available categories.
  /// If Firestore collection is empty, returns the standard default categories from the SRS.
  Future<List<CategoryModel>> getCategories() async {
    try {
      final snapshot = await _categoriesRef.get();
      if (snapshot.docs.isEmpty) {
        return CategoryModel.defaultCategories;
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    } catch (_) {
      // In case of network/permission issues during offline/early setup, return default categories
      return CategoryModel.defaultCategories;
    }
  }

  /// Real-time stream of product categories.
  Stream<List<CategoryModel>> categoriesStream() {
    return _categoriesRef.snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) {
        return CategoryModel.defaultCategories;
      }
      return snapshot.docs
          .map((doc) => CategoryModel.fromFirestore(doc))
          .toList();
    });
  }
}
