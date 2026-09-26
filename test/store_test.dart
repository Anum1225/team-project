import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/models.dart';
import 'package:untitled/src/preview_store.dart';

void main() async {
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
