import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadHarvestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in {
    'Manrope': 'Manrope.ttf',
    'DMSerifDisplay': 'DMSerifDisplay-Regular.ttf',
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(rootBundle.load('assets/fonts/${entry.value}'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
