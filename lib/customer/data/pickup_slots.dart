import '../utils/formatters.dart';

List<String> pickupSlots() {
  final tomorrow = DateTime.now().add(const Duration(days: 1));
  final next = DateTime.now().add(const Duration(days: 2));
  return [
    '${dateLabel(tomorrow)} · 9:00–11:00 AM',
    '${dateLabel(tomorrow)} · 2:00–4:00 PM',
    '${dateLabel(next)} · 9:00–11:00 AM',
  ];
}
