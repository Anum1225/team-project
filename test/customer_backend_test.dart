import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/exceptions/app_exceptions.dart';
import 'package:untitled/models/models.dart';
import 'package:untitled/services/services.dart';

void main() {
  group('UserModel Tests', () {
    test('Should create UserModel and correctly serialize to/from map', () {
      final now = DateTime(2026, 9, 24, 12, 0);
      final user = UserModel(
        userId: 'usr_001',
        name: 'Sarah Customer',
        email: 'sarah@example.com',
        phone: '+1234567890',
        address: '123 Market Street, Apt 4B',
        role: 'Customer',
        createdAt: now,
      );

      expect(user.isCustomer, isTrue);

      final map = user.toMap();
      expect(map['userId'], 'usr_001');
      expect(map['name'], 'Sarah Customer');
      expect(map['email'], 'sarah@example.com');
      expect(map['phone'], '+1234567890');
      expect(map['address'], '123 Market Street, Apt 4B');
      expect(map['role'], 'Customer');

      // Deserialize
      final parsed = UserModel.fromMap(map);
      expect(parsed.userId, 'usr_001');
      expect(parsed.name, 'Sarah Customer');
      expect(parsed.email, 'sarah@example.com');
      expect(parsed.phone, '+1234567890');
      expect(parsed.address, '123 Market Street, Apt 4B');
      expect(parsed.role, 'Customer');
      expect(parsed.isCustomer, isTrue);
    });

    test('Should parse SRS schema keys (User_Id, Created_At, Role)', () {
      final srsMap = {
        'User_Id': 'usr_srs_002',
        'Name': 'John Doe',
        'Email': 'john@example.com',
        'Phone': '555-1234',
        'Address': 'Farm Lane 12',
        'Role': 'Customer',
        'Created_At': '2026-09-24T10:00:00.000Z',
      };

      final user = UserModel.fromMap(srsMap);
      expect(user.userId, 'usr_srs_002');
      expect(user.name, 'John Doe');
      expect(user.isCustomer, isTrue);
    });

    test('Farmer role should not be recognized as customer', () {
      final farmerUser = UserModel(
        userId: 'farm_001',
        name: 'Farmer Bob',
        email: 'bob@farmer.com',
        phone: '123456789',
        address: 'Green Farm',
        role: 'Farmer',
        createdAt: DateTime.now(),
      );

      expect(farmerUser.isCustomer, isFalse);
    });
  });

  group('ProductModel Tests', () {
    test('Should correctly detect stock availability', () {
      const inStockProduct = ProductModel(
        productId: 'prod_1',
        farmerId: 'farmer_1',
        itemName: 'Fresh Carrots',
        category: 'Vegetables',
        pricePerUnit: 2.50,
        stockQty: 50,
      );

      expect(inStockProduct.isInStock, isTrue);
      expect(inStockProduct.isOutOfStock, isFalse);

      const outOfStockProduct = ProductModel(
        productId: 'prod_2',
        farmerId: 'farmer_1',
        itemName: 'Organic Strawberries',
        category: 'Fruits',
        pricePerUnit: 4.00,
        stockQty: 0,
      );

      expect(outOfStockProduct.isInStock, isFalse);
      expect(outOfStockProduct.isOutOfStock, isTrue);
    });

    test('Should parse SRS schema keys (Item_Name, Price_Per_Unit, Stock_Qty)', () {
      final map = {
        'Product_Id': 'prod_srs_10',
        'Farmer_Id': 'farmer_33',
        'Item_Name': 'Organic Honey',
        'Category': 'Organic Products',
        'Price_Per_Unit': 8.5,
        'Stock_Qty': 20,
        'Image_Url': 'https://example.com/honey.png',
      };

      final prod = ProductModel.fromMap(map);
      expect(prod.productId, 'prod_srs_10');
      expect(prod.itemName, 'Organic Honey');
      expect(prod.category, 'Organic Products');
      expect(prod.pricePerUnit, 8.5);
      expect(prod.stockQty, 20);
      expect(prod.isInStock, isTrue);
    });
  });

  group('CartItemModel Tests', () {
    test('Should accurately calculate subtotal', () {
      final item = CartItemModel(
        productId: 'prod_1',
        productName: 'Fresh Tomatoes',
        pricePerUnit: 3.50,
        quantity: 4,
        addedAt: DateTime.now(),
      );

      expect(item.subtotal, 14.00);

      final updated = item.copyWith(quantity: 10);
      expect(updated.quantity, 10);
      expect(updated.subtotal, 35.00);
    });
  });

  group('OrderModel and OrderItemModel Tests', () {
    test('Should build valid OrderModel with calculated items and statuses', () {
      final items = [
        const OrderItemModel(
          productId: 'prod_1',
          productName: 'Tomatoes',
          quantity: 2,
          unitPrice: 3.0,
          subtotal: 6.0,
        ),
        const OrderItemModel(
          productId: 'prod_2',
          productName: 'Spinach',
          quantity: 3,
          unitPrice: 2.0,
          subtotal: 6.0,
        ),
      ];

      final now = DateTime(2026, 9, 24);
      final order = OrderModel(
        orderId: 'ord_999',
        customerId: 'usr_001',
        farmerId: 'farmer_01',
        items: items,
        totalPrice: 12.0,
        status: OrderModel.statusPending,
        createdAt: now,
        deliveryAddress: 'Green Valley 4',
      );

      expect(order.isPending, isTrue);
      expect(order.isCancelled, isFalse);
      expect(order.totalItemCount, 5);
      expect(order.totalPrice, 12.0);

      final map = order.toMap();
      expect(map['orderId'], 'ord_999');
      expect(map['totalPrice'], 12.0);
      expect(map['status'], OrderModel.statusPending);

      final parsed = OrderModel.fromMap(map);
      expect(parsed.orderId, 'ord_999');
      expect(parsed.items.length, 2);
      expect(parsed.items.first.productName, 'Tomatoes');
    });
  });

  group('CategoryModel Tests', () {
    test('SRS default categories must contain the 7 standard agricultural categories', () {
      final categories = CategoryModel.defaultCategories;
      final names = categories.map((c) => c.name).toList();

      expect(names, contains('Fruits'));
      expect(names, contains('Vegetables'));
      expect(names, contains('Grains'));
      expect(names, contains('Dairy'));
      expect(names, contains('Pulses'));
      expect(names, contains('Herbs and Spices'));
      expect(names, contains('Organic Products'));
    });
  });

  group('FarmerModel Tests', () {
    test('Should serialize and deserialize correctly', () {
      final farmer = FarmerModel(
        farmerId: 'farmer_101',
        userId: 'usr_f1',
        businessName: 'Sunny Acre Farms',
        description: 'Eco-friendly family farm',
        rating: 4.8,
        followedAt: DateTime.now(),
      );

      final map = farmer.toMap();
      expect(map['businessName'], 'Sunny Acre Farms');
      expect(map['rating'], 4.8);

      final parsed = FarmerModel.fromMap(map);
      expect(parsed.farmerId, 'farmer_101');
      expect(parsed.businessName, 'Sunny Acre Farms');
      expect(parsed.rating, 4.8);
    });
  });

  group('Exception and Error Handling Tests', () {
    test('AuthException.fromFirebaseCode maps codes correctly', () {
      final ex1 = AuthException.fromFirebaseCode('wrong-password');
      expect(ex1.message, contains('Incorrect email or password'));

      final ex2 = AuthException.fromFirebaseCode('user-not-found');
      expect(ex2.message, contains('No account found'));

      final ex3 = AuthException.fromFirebaseCode('weak-password');
      expect(ex3.message, contains('at least 6 characters'));

      final ex4 = AuthException.fromFirebaseCode('requires-recent-login');
      expect(ex4.message, contains('recent authentication'));
    });
  });

  group('Service Logic and Validation Tests', () {
    test('AuthService registration should validate required fields before network call', () async {
      // Mocking or null auth/firestore will throw validation errors immediately
      // before attempting any Firebase calls:
      final authService = AuthService();

      // Empty name
      expect(
        () => authService.registerCustomer(
          name: '',
          email: 'test@example.com',
          password: 'password123',
          phone: '1234567890',
          address: 'Main St',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-name')),
      );

      // Weak password
      expect(
        () => authService.registerCustomer(
          name: 'Valid Name',
          email: 'test@example.com',
          password: '123',
          phone: '1234567890',
          address: 'Main St',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'weak-password')),
      );

      // Empty phone
      expect(
        () => authService.registerCustomer(
          name: 'Valid Name',
          email: 'test@example.com',
          password: 'password123',
          phone: '',
          address: 'Main St',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-phone')),
      );

      // Empty address
      expect(
        () => authService.registerCustomer(
          name: 'Valid Name',
          email: 'test@example.com',
          password: 'password123',
          phone: '1234567890',
          address: '',
        ),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-address')),
      );
    });

    test('AuthService login should validate empty credentials', () async {
      final authService = AuthService();

      expect(
        () => authService.loginCustomer(email: '', password: 'password'),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'invalid-email')),
      );

      expect(
        () => authService.loginCustomer(email: 'user@example.com', password: ''),
        throwsA(isA<AuthException>().having((e) => e.code, 'code', 'missing-password')),
      );
    });
  });
}
