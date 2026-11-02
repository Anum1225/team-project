/// Existing bundled photographs. This resolves display images only: it never
/// selects a photo in a new-product form or writes demo records to the backend.
const productPhotoAssets = <String, String>{
  'tomato': 'tomatoes',
  'carrot': 'carrots',
  'potato': 'potatoes',
  'apple': 'apples',
  'pear': 'pears',
  'peach': 'peaches',
  'strawberry': 'strawberries',
  'spinach': 'spinach',
  'corn': 'corn',
  'egg': 'eggs',
  'honey': 'honey',
  'avocado': 'p_avocado',
  'banana': 'p_banana',
  'basil': 'p_basil',
  'butter': 'p_butter',
  'chickpea': 'p_chickpea',
  'coriander': 'p_coriander',
  'cucumber': 'p_cucumber',
  'kidneybean': 'p_kidneybean',
  'lentil': 'p_lentil',
  'milk': 'p_milk',
  'mint': 'p_mint',
  'mung': 'p_mung',
  'oat': 'p_oats',
  'paneer': 'p_paneer',
  'rice': 'p_rice',
  'rosemary': 'p_rosemary',
  'wheat': 'p_wheat',
  'yogurt': 'p_yogurt',
};

String productDisplayImage(String image, String name) {
  final stored = image.trim();
  // Preserve all user uploads, remote URLs and explicit product photos.
  if (stored.isNotEmpty &&
      !{'farm', 'farm.jpg', 'assets/images/farm.jpg'}.contains(stored)) {
    final key = stored
        .replaceFirst('assets/images/', '')
        .replaceFirst(
          RegExp(r'\.(jpg|jpeg|png|webp)$', caseSensitive: false),
          '',
        )
        .toLowerCase();
    // Only exact historical asset aliases can be remapped. Custom filenames,
    // paths, network URLs and data URIs are never inferred from their words.
    return _assetAliases[key] ?? stored;
  }
  return _photoForName(name) ?? stored;
}

final _assetAliases = <String, String>{
  for (final entry in productPhotoAssets.entries) entry.key: entry.value,
  for (final entry in productPhotoAssets.entries) '${entry.key}s': entry.value,
  'tomatoes': 'tomatoes',
  'potatoes': 'potatoes',
  'peaches': 'peaches',
  'strawberries': 'strawberries',
  'yoghurt': 'p_yogurt',
};

String? _photoForName(String name) {
  final words = name
      .toLowerCase()
      .replaceAll('kidney beans', 'kidneybean')
      .replaceAll('kidney bean', 'kidneybean')
      .split(RegExp(r'[^a-z]+'));
  final matches = <String>{};
  for (var word in words) {
    if (word == 'strawberries') word = 'strawberry';
    if (word == 'tomatoes') word = 'tomato';
    if (word == 'potatoes') word = 'potato';
    if (word == 'peaches') word = 'peach';
    if (word == 'yoghurt') word = 'yogurt';
    if (!productPhotoAssets.containsKey(word) && word.endsWith('s')) {
      word = word.substring(0, word.length - 1);
    }
    final asset = productPhotoAssets[word];
    if (asset != null) matches.add(asset);
  }
  // Mixed/unknown products retain their existing placeholder instead of guessing.
  return matches.length == 1 ? matches.single : null;
}
