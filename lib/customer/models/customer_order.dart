import 'order_line.dart';

class CustomerOrder {
  CustomerOrder({
    required this.id,
    required this.date,
    required this.lines,
    required this.address,
    required this.pickups,
    this.status = 'Pending',
  });
  final String id, address;
  final DateTime date;
  final List<OrderLine> lines;
  final Map<String, String> pickups;
  String status;
  int get total => lines.fold(0, (sum, l) => sum + l.total);
}
