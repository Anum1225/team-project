import 'models.dart';
import 'store.dart';

/// Explicit test fixture; never constructed by the production entry point.
class PreviewStore extends HarvestStore {
  PreviewStore({bool seed = true}) {
    if (seed) _seed();
  }
  void _seed() {
    categories.addAll([
      'Vegetables',
      'Fruits',
      'Dairy',
      'Grains',
      'Herbs',
      'Organic',
      'Pulses',
      'Pantry',
    ]);
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
        name: 'Marcus Rivera',
        email: 'marcus@example.com',
        role: UserRole.farmer,
        phone: '0300 7654321',
        address: 'Stall #14 • Greenwood Market',
      ),
      Account(
        id: 'f2',
        name: 'Sunny Brook',
        email: 'sunny@example.com',
        role: UserRole.farmer,
        phone: '0300 1234567',
        address: 'Sunny Brook Farm, 2.1 mi',
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
        name: 'Greenwood Organic Farm',
        owner: 'f1',
        location: 'Stall #14 • Greenwood Market',
        market: 'Greenwood Farmers Market',
        description:
            'Marcus Rivera · 8 yrs regenerative certified. Growing vine-ripened heirloom beefsteaks and fresh baby greens.',
        image: 'farmer_marcus',
      ),
      Farm(
        id: 'sun',
        name: 'Sunny Brook Farm',
        owner: 'f2',
        location: '2.1 mi away · Greenwood Market',
        market: 'Greenwood Farmers Market',
        description:
            'Certified organic vegetables, crisp greens and heritage berries harvested fresh daily.',
        image: 'farmer_sunny',
      ),
      Farm(
        id: 'highland',
        name: 'Highland Orchards',
        owner: 'f1',
        location: '3.8 mi away · Hillside',
        market: 'Greenwood Farmers Market',
        description:
            'Fresh crisp Honeycrisp apples, Asian pears, and orchard cider.',
        image: 'farm',
      ),
      Farm(
        id: 'golden',
        name: 'Golden Hen Homestead',
        owner: 'f2',
        location: '1.4 mi away · Valley Pastures',
        market: 'Greenwood Farmers Market',
        description: 'Pasture-raised farm eggs from happy, roaming hens.',
        image: 'eggs',
      ),
      Farm(
        id: 'willow',
        name: 'Willow Creek Farms',
        owner: 'f1',
        location: '2.9 mi away · Riverside',
        market: 'Greenwood Farmers Market',
        description:
            'Sweet summer corn, crisp melons and wholesome farm harvests.',
        image: 'corn',
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
        description:
            'Bright, juicy tomatoes with a beautifully balanced sweetness. A kitchen essential for a slow-cooked sauce or a simple seasonal salad.',
      ),
      Product(
        id: 'san_marzano',
        name: 'San Marzano Heirlooms',
        category: 'Vegetables',
        farmId: 'sun',
        price: 18000,
        stock: 24,
        image: 'tomatoes',
        unit: '1 lb',
        description:
            'Plump, deeply flavorful Italian San Marzano heirloom crop, harvested at peak sweetness for pasta and salads.',
      ),
      Product(
        id: 'honeycrisp',
        name: 'Crisp Honeycrisp Apples',
        category: 'Fruits',
        farmId: 'highland',
        price: 16000,
        stock: 45,
        image: 'pears',
        unit: '1 lb',
        description:
            'Crisp, sweet, and bursting with orchard juice, harvested early this morning.',
      ),
      Product(
        id: 'eggs',
        name: 'Pasture Raised Eggs',
        category: 'Dairy & Eggs',
        farmId: 'golden',
        price: 25000,
        stock: 12,
        image: 'eggs',
        unit: '1 doz',
        description:
            'Rich golden yolks from pasture-raised hens grazing in sunshine.',
      ),
      Product(
        id: 'corn',
        name: 'Sweet Summer Corn',
        category: 'Vegetables',
        farmId: 'willow',
        price: 18000,
        stock: 30,
        image: 'corn',
        unit: '6 ears',
        description:
            'Tender, sweet summer corn on the cob, freshly plucked from the stalks.',
      ),
      Product(
        id: 'spinach',
        name: 'Baby Spinach (8oz)',
        category: 'Vegetables',
        farmId: 'green',
        price: 15000,
        stock: 3,
        image: 'spinach',
        unit: '8 oz',
        description:
            'Tender baby spinach leaves, triple washed and sealed in eco packaging.',
      ),
      Product(
        id: 'peaches',
        name: 'Yellow Peaches',
        category: 'Fruits',
        farmId: 'green',
        price: 14000,
        stock: 0,
        image: 'peaches',
        unit: '1 lb',
        description:
            'Sun-drenched yellow peaches from our south orchard slope. Sold out for today.',
      ),
      Product(
        id: 'beefsteak',
        name: 'Heirloom Beefsteak',
        category: 'Vegetables',
        farmId: 'green',
        price: 18000,
        stock: 18,
        image: 'tomatoes',
        unit: '1 lb',
        description:
            'Giant heirloom beefsteak tomatoes with rich, traditional summer garden flavor.',
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
        description:
            'A little sweetness, straight from the field. Enjoy these strawberries on their own, over breakfast, or folded into your favourite dessert.',
      ),
      Product(
        id: 'carrot',
        name: 'Farm carrots',
        category: 'Vegetables',
        farmId: 'green',
        price: 14000,
        stock: 4,
        image: 'farm',
        description:
            'Earthy, crisp carrots, wonderful roasted or shaved into a crunchy salad. Wash well before enjoying.',
      ),
      Product(
        id: 'potato',
        name: 'Golden potatoes',
        category: 'Vegetables',
        farmId: 'green',
        price: 12000,
        stock: 32,
        image: 'potatoes',
        description:
            'Versatile, comforting potatoes for your everyday table. Bake, mash, or roast until golden.',
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
        description:
            'A rich floral honey for tea, toast, and slow weekend breakfasts. Store sealed in a cool, dry place.',
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
        description:
            'A generous box for sharing. This harvest has sold out; explore the farm for other available produce.',
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

  @override
  Future<String?> signIn(String email, String password) async {
    final clean = email.trim().toLowerCase();
    Account? match;
    for (final a in accounts) {
      if (a.email.toLowerCase() == clean) {
        match = a;
        break;
      }
    }
    if (match != null) {
      if (!match.active) {
        return 'This account is suspended.';
      }
      role = match.role;
      notifyListeners();
      return null;
    }
    return 'Invalid credentials or user not found.';
  }

  @override
  Future<String?> register(
    String email,
    String password,
    String name,
    String phone,
    String address,
    UserRole selected,
  ) async {
    if (selected == UserRole.admin) {
      return 'Administrator accounts cannot be self-registered.';
    }
    final clean = email.trim().toLowerCase();
    if (accounts.any((a) => a.email.toLowerCase() == clean)) {
      return 'An account already uses this email. Please sign in.';
    }
    final uid = 'u-${DateTime.now().millisecondsSinceEpoch}';
    final newAcc = Account(
      id: uid,
      name: name.trim().isEmpty ? 'New User' : name.trim(),
      email: email.trim(),
      role: selected,
      phone: phone.trim(),
      address: address.trim(),
    );
    accounts.add(newAcc);
    if (selected == UserRole.farmer) {
      farms.add(
        Farm(
          id: uid,
          name: '${newAcc.name} Farm',
          owner: uid,
          location: address.trim(),
          market: 'Local Market',
          description: 'Local producer fresh harvests.',
          image: 'farm',
        ),
      );
    }
    role = selected;
    notifyListeners();
    return null;
  }

  @override
  Future<String?> resetPassword(String email) async {
    if (!email.contains('@')) return 'Enter a valid email address.';
    return null;
  }

  @override
  Future<String?> changePassword(String old, String password) async => null;

  @override
  Future<String?> sendFeedback(String email, String message) async => null;
}
