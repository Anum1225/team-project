import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/products/product_images.dart';
import 'package:untitled/src/features/common/data/models.dart';

void main() {
  test('every mapped product photo already exists in assets', () {
    for (final entry in productPhotoAssets.entries) {
      expect(
        File('assets/images/${entry.value}.jpg').existsSync(),
        true,
        reason: entry.key,
      );
    }
  });
  test('missing and old product placeholders use matching bundled photos', () {
    expect(productDisplayImage('', 'Fresh farm carrots'), 'carrots');
    expect(productDisplayImage('farm', 'Organic red lentils'), 'p_lentil');
    expect(productDisplayImage('milk', 'Farm milk'), 'p_milk');
    expect(productDisplayImage('', 'Strawberries'), 'strawberries');
    expect(productDisplayImage('', 'Kidney beans'), 'p_kidneybean');
    expect(productDisplayImage('', 'Mystery box'), '');
    expect(productDisplayImage('', 'Tomato and carrot mix'), '');
  });
  test(
    'uploads and explicit photos are retained without changing model data',
    () {
      for (final image in [
        'https://example.com/carrot.jpg',
        'data:image/png;base64,abc',
        'p_carrot',
        'assets/images/p_carrot.jpg',
        'my_milk_photo.jpg',
        'file:///photos/carrot.jpg',
      ]) {
        expect(productDisplayImage(image, 'Carrot'), image);
      }
      final product = Product(
        id: 'test',
        name: 'Fresh milk',
        category: 'Dairy',
        farmId: 'f',
        price: 100,
        stock: 1,
        image: '',
      );
      expect(product.displayImage, 'p_milk');
      expect(product.image, '');
    },
  );
}
