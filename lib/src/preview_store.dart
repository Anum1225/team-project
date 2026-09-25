import 'models.dart';
import 'store.dart';

/// Explicit test fixture; never constructed by the production entry point.
class PreviewStore extends HarvestStore {
  PreviewStore({bool seed = true}) {
    if (seed) _seed();
  }
  void _seed() {
    categories.addAll(['Vegetables','Fruits','Dairy','Grains','Herbs','Organic','Pulses','Pantry']);
    accounts.addAll([
      Account(
        id: 'c1',
        name: 'Yahya Khan',
        email: 'yahya@example.com',
        role: UserRole.customer,
        phone: '0300 1234567',
        address: '12 Garden Lane, Karachi',
      ),
      Account(
        id: 'c2',
        name: 'Ayesha Ali',
        email: 'ayesha@example.com',
        role: UserRole.customer,
        address: '8 Park Road, Karachi',
      ),
      Account(
        id: 'f1',
        name: 'Ahmed Raza',
        email: 'ahmed@example.com',
        role: UserRole.farmer,
        phone: '0300 7654321',
        address: 'Malir, Karachi',
      ),
      Account(
        id: 'f2',
        name: 'Sara Noor',
        email: 'sara@example.com',
        role: UserRole.farmer,
        address: 'Gadap, Karachi',
      ),
      Account(
        id: 'a1',
        name: 'Harvest team',
        email: 'admin@example.com',
        role: UserRole.admin,
      ),
    ]);
    farms.addAll([
      Farm(
        id: 'green',
        name: 'Green Valley Farm',
        owner: 'f1',
        location: 'Malir, Karachi',
        market: 'Sunday Farmers Market',
        description: 'A family farm with a simple belief: good food begins with care. We grow small batches, follow the seasons, and love sharing what comes out of our soil.',
        image: 'farm',
      ),
      Farm(
        id: 'sun',
        name: 'Sunfield Organics',
        owner: 'f2',
        location: 'Gadap, Karachi',
        market: 'Community Market',
        description: 'Seasonal fruit and pantry favourites from our family to yours. Get to know the people behind your everyday ingredients.',
        image: 'market',
      ),
    ]);
    products.addAll([
      Product(
        id: 'tomato',
        name: 'Vine tomatoes',
        category: 'Vegetables',
        farmId: 'green',
        price: 18000,
        stock: 24,
        image: 'tomatoes',
        description: 'Bright, juicy tomatoes with a beautifully balanced sweetness. A kitchen essential for a slow-cooked sauce or a simple seasonal salad.',
      ),
      Product(
        id: 'berry',
        name: 'Sweet strawberries',
        category: 'Fruits',
        farmId: 'sun',
        price: 32000,
        stock: 8,
        image: 'strawberries',
        unit: '250 g',
        description: 'A little sweetness, straight from the field. Enjoy these strawberries on their own, over breakfast, or folded into your favourite dessert.',
      ),
      Product(
        id: 'carrot',
        name: 'Farm carrots',
        category: 'Vegetables',
        farmId: 'green',
        price: 14000,
        stock: 4,
        image: 'farm',
        description: 'Earthy, crisp carrots, wonderful roasted or shaved into a crunchy salad. Wash well before enjoying.',
      ),
      Product(
        id: 'potato',
        name: 'Golden potatoes',
        category: 'Vegetables',
        farmId: 'green',
        price: 12000,
        stock: 32,
        image: 'potatoes',
        description: 'Versatile, comforting potatoes for your everyday table. Bake, mash, or roast until golden.',
      ),
      Product(
        id: 'honey',
        name: 'Wildflower honey',
        category: 'Pantry',
        farmId: 'sun',
        price: 85000,
        stock: 6,
        image: 'honey',
        unit: '350 g',
        description: 'A rich floral honey for tea, toast, and slow weekend breakfasts. Store sealed in a cool, dry place.',
      ),
      Product(
        id: 'berry2',
        name: 'Strawberry harvest box',
        category: 'Fruits',
        farmId: 'green',
        price: 110000,
        stock: 0,
        image: 'strawberries',
        unit: '1 kg',
        description: 'A generous box for sharing. This harvest has sold out; explore the farm for other available produce.',
      ),
    ]);
    final now = DateTime.now();
    for (var i = 0; i < 4; i++) {
      final p = products[i];
      final f = farm(p.farmId);
      orders.add(
        HarvestOrder(
          id: 'HH-${1040 + i}',
          customerId: i == 1 ? 'c2' : 'c1',
          customerName: i == 1 ? 'Ayesha Ali' : 'Yahya Khan',
          farmId: f.id,
          farmName: f.name,
          date: now.subtract(Duration(days: i * 2, hours: 2)),
          address: '12 Garden Lane, Karachi',
          items: [
            OrderLine(
              productId: p.id,
              name: p.name,
              image: p.image,
              unit: p.unit,
              price: p.price,
              quantity: 2,
            ),
          ],
          status: [
            OrderStatus.pending,
            OrderStatus.confirmed,
            OrderStatus.ready,
            OrderStatus.completed,
          ][i],
        ),
      );
    }
  }
}
