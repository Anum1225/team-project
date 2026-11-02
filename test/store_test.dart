import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/data/models.dart';

import 'fixtures/preview_store.dart';

void main() async {
  test(
    'catalog groups farm offers but preserves units and seller inventory',
    () {
      final store = PreviewStore();
      final original = store.product('tomato')!;
      final second = Product(
        id: 'tomato-other-farm',
        name: '  ${original.name.toUpperCase()} ',
        category: original.category,
        farmId: 'sun',
        price: original.price + 100,
        stock: 8,
        image: original.image,
        unit: original.unit,
      );
      store.products.addAll([second, original]);
      expect(
        store
            .catalogProducts(store.products)
            .where((p) => store.catalogKey(p) == store.catalogKey(original)),
        hasLength(1),
      );
      expect(store.offersFor(original), hasLength(2));
      expect(store.catalogProducts([second, original]).single.id, original.id);
      original.stock = 0;
      expect(store.catalogProducts([original, second]).single.id, second.id);
      second.unit = 'box';
      expect(store.catalogProducts([original, second]), hasLength(2));
      store.role = UserRole.farmer;
      expect(
        store.visibleProducts.where((p) => p.id == original.id),
        hasLength(1),
      );
      expect(store.visibleProducts.any((p) => p.id == second.id), isFalse);
      expect(store.canManage(second), isFalse);
    },
  );
  test('shared login detects each existing account role', () async {
    final store = PreviewStore();
    for (final role in UserRole.values) {
      final account = store.accounts.firstWhere((a) => a.role == role);
      expect(await store.signIn(account.email, 'preview-password'), isNull);
      expect(store.role, role);
    }
    expect(
      await store.signIn('unknown@example.com', 'preview-password'),
      isNotNull,
    );
  });
  test(
    'stock limits reject zero stock and keep failed checkout atomic',
    () async {
      final store = PreviewStore();
      expect(store.setQuantity('berry2', 1), isNotNull);
      expect(store.setQuantity('tomato', 25), isNotNull);
      expect(store.setQuantity('tomato', 2), isNull);
      expect(store.setQuantity('berry', 2), isNull);
      final before = store.orders.length;
      store.product('berry')!.stock = 1;
      expect(() => store.checkout('Test address'), throwsStateError);
      expect(store.orders.length, before);
      expect(store.product('tomato')!.stock, 24);
      expect(store.basketCount, 4);
      expect(store.basketProductCount, 2);
    },
  );

  test('checkout groups farms and preserves historical item details', () async {
    final store = PreviewStore();
    store.setQuantity('tomato', 2);
    store.setQuantity('berry', 1);
    final orders = await store.checkout('12 Garden Lane');
    expect(orders.length, 2);
    expect(orders.fold<int>(0, (sum, order) => sum + order.total), 68000);
    expect(store.basket, isEmpty);
    expect(store.product('tomato')!.stock, 22);
    store.product('tomato')!
      ..name = 'Changed'
      ..price = 99000;
    expect(orders.first.items.first.name, 'Vine tomatoes');
    expect(orders.first.total, 36000);
  });

  test(
    'role boundaries and cancellation restore inventory exactly once',
    () async {
      final store = PreviewStore();
      store.setQuantity('tomato', 2);
      final order = (await store.checkout('Address')).single;
      expect(store.updateStatus(order, OrderStatus.confirmed), isNotNull);
      store.chooseRole(UserRole.farmer);
      expect(store.setQuantity('tomato', 1), isNotNull);
      final anotherFarmOrder = store.orders.firstWhere(
        (o) => o.farmId == 'sun',
      );
      expect(
        store.updateStatus(anotherFarmOrder, OrderStatus.cancelled),
        isNotNull,
      );
      expect(store.updateStatus(order, OrderStatus.completed), isNotNull);
      expect(store.updateStatus(order, OrderStatus.cancelled), isNull);
      expect(store.product('tomato')!.stock, 24);
      expect(store.updateStatus(order, OrderStatus.cancelled), isNotNull);
      expect(store.product('tomato')!.stock, 24);
    },
  );

  test('categories migrate products and reject destructive removal', () async {
    final store = PreviewStore()..chooseRole(UserRole.admin);
    expect(store.deleteCategory('Vegetables'), isNotNull);
    expect(
      store.saveCategory('Garden vegetables', previous: 'Vegetables'),
      isNull,
    );
    expect(store.product('tomato')!.category, 'Garden vegetables');
    expect(store.saveCategory('Fruits'), isNotNull);
    expect(store.deleteCategory('Grains'), isNull);
  });

  test('suspended sellers cannot receive new orders', () async {
    final store = PreviewStore();
    store.setQuantity('tomato', 1);
    store.chooseRole(UserRole.admin);
    store.toggleAccount(store.accounts.firstWhere((a) => a.id == 'f1'));
    store.chooseRole(UserRole.customer);
    expect(() => store.checkout('Address'), throwsStateError);
    expect(store.setQuantity('tomato', 2), isNotNull);
  });
}
