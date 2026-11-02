part of 'orders.dart';

IconData statusIcon(OrderStatus status) => switch (status) {
  OrderStatus.pending => Icons.schedule,
  OrderStatus.confirmed => Icons.task_alt,
  OrderStatus.ready => Icons.storefront_outlined,
  OrderStatus.completed => Icons.check_circle_outline,
  OrderStatus.cancelled => Icons.cancel_outlined,
};
