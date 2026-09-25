import 'product.dart';

class OrderLine {
  const OrderLine(this.product, this.quantity);
  final Product product;
  final int quantity;
  int get total => product.price * quantity;
}
