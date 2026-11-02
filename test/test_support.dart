import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> loadHarvestFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final entry in {
    'Outfit': 'Outfit.ttf',
    'Manrope': 'Manrope.ttf',
    'Fraunces': 'Fraunces.ttf',
  }.entries) {
    final loader = FontLoader(entry.key)
      ..addFont(rootBundle.load('assets/fonts/${entry.value}'));
    await loader.load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
  await icons.load();
}
