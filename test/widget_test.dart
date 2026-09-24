import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/main.dart';

void main() {
  testWidgets('HarvestHub app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const HarvestHubApp());
    expect(find.text('HarvestHub'), findsWidgets);
    expect(find.text('Ready for work'), findsOneWidget);
  });
}
