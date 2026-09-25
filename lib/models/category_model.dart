import 'package:cloud_firestore/cloud_firestore.dart';

/// Product category model in HarvestHub.
class CategoryModel {
  final String categoryId;
  final String name;
  final String description;
  final String imageUrl;

  const CategoryModel({
    required this.categoryId,
    required this.name,
    this.description = '',
    this.imageUrl = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'categoryId': categoryId,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
    };
  }

  factory CategoryModel.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return CategoryModel(
      categoryId: (map['categoryId'] ?? documentId ?? map['name'] ?? '').toString(),
      name: (map['name'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      imageUrl: (map['imageUrl'] ?? '').toString(),
    );
  }

  factory CategoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CategoryModel.fromMap(data, documentId: doc.id);
  }

  /// Default predefined categories based on the HarvestHub SRS (Section 1.6).
  static const List<CategoryModel> defaultCategories = [
    CategoryModel(
      categoryId: 'fruits',
      name: 'Fruits',
      description: 'Fresh seasonal and organic fruits',
    ),
    CategoryModel(
      categoryId: 'vegetables',
      name: 'Vegetables',
      description: 'Farm-fresh green and root vegetables',
    ),
    CategoryModel(
      categoryId: 'grains',
      name: 'Grains',
      description: 'Wholesome wheat, rice, corn and millets',
    ),
    CategoryModel(
      categoryId: 'dairy',
      name: 'Dairy',
      description: 'Fresh milk, cheese, butter and yogurt',
    ),
    CategoryModel(
      categoryId: 'pulses',
      name: 'Pulses',
      description: 'Nutritious lentils, beans and legumes',
    ),
    CategoryModel(
      categoryId: 'herbs_spices',
      name: 'Herbs and Spices',
      description: 'Natural aromatic culinary and medicinal herbs',
    ),
    CategoryModel(
      categoryId: 'organic_products',
      name: 'Organic Products',
      description: 'Certified pesticide-free produce',
    ),
  ];

  @override
  String toString() => 'CategoryModel(name: $name)';
}
