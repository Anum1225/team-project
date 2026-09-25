import '../models/customer_order.dart';
import '../models/customer_profile.dart';
import '../models/order_line.dart';
import '../models/product.dart';

abstract final class CustomerCodec {
  static Map<String, dynamic> profile(CustomerProfile p) => {
    'name': p.name,
    'email': p.email,
    'phone': p.phone,
    'address': p.address,
  };
  static CustomerProfile readProfile(Map<String, dynamic> data) =>
      CustomerProfile(
        name: data['name'] as String? ?? '',
        email: data['email'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
        address: data['address'] as String? ?? '',
      );
  static Map<String, dynamic> product(Product p) => {
    'id': p.id,
    'name': p.name,
    'category': p.category,
    'price': p.price,
    'unit': p.unit,
    'stock': p.stock,
    'farmerId': p.farmerId,
    'symbol': p.symbol,
    'color': p.color,
    'description': p.description,
    'organic': p.organic,
  };
  static Product readProduct(Map<String, dynamic> p) => Product(
    p['id'] as String,
    p['name'] as String,
    p['category'] as String,
    (p['price'] as num).toInt(),
    p['unit'] as String,
    (p['stock'] as num).toInt(),
    p['farmerId'] as String,
    p['symbol'] as String? ?? '',
    (p['color'] as num).toInt(),
    p['description'] as String,
    organic: p['organic'] == true,
  );
  static Map<String, dynamic> order(CustomerOrder o) => {
    'id': o.id,
    'date': o.date.toUtc().toIso8601String(),
    'address': o.address,
    'pickups': o.pickups,
    'status': o.status,
    'total': o.total,
    'simulated': true,
    'lines': o.lines
        .map((l) => {'product': product(l.product), 'quantity': l.quantity})
        .toList(),
  };
  static CustomerOrder readOrder(Map<String, dynamic> o) => CustomerOrder(
    id: o['id'] as String,
    date: DateTime.parse(o['date'] as String).toLocal(),
    address: o['address'] as String,
    status: o['status'] as String? ?? 'Pending',
    pickups: Map<String, String>.from(o['pickups'] as Map? ?? {}),
    lines: (o['lines'] as List).map((raw) {
      final line = Map<String, dynamic>.from(raw as Map);
      return OrderLine(
        readProduct(Map<String, dynamic>.from(line['product'] as Map)),
        (line['quantity'] as num).toInt(),
      );
    }).toList(),
  );
}
