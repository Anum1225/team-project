import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared defaults keep the public page and the administrator's draft in sync.
class PublicContent {
  PublicContent.fromData(Map<String, dynamic>? data)
    : values = Map.unmodifiable({
        for (final entry in defaults.entries)
          entry.key: data?[entry.key] is String
              ? data![entry.key] as String
              : entry.value,
        // The old editor often stored an empty extra paragraph. Preserve the
        // original story until an administrator publishes the full page.
        if (data?['aboutVersion'] != 1 &&
            (data?['about'] is! String ||
                (data!['about'] as String).trim().isEmpty))
          'about': defaults['about']!,
      });

  final Map<String, String> values;
  String operator [](String key) => values[key] ?? '';

  static const defaults = <String, String>{
    'aboutPageTitle': 'Our story',
    'aboutEyebrow': 'Rooted in something good',
    'aboutHeadline': 'Good food starts\ncloser to home.',
    'aboutImage': 'market',
    'aboutImageLabel': 'A colourful market of fresh produce',
    'aboutStoryTitle': 'A market with meaning.',
    'about': 'HarvestHub brings local farmers and everyday food lovers together. A place to discover what’s growing, meet the people who grow it, and make thoughtful choices for your table.',
    'aboutCommunityTitle': 'Good for your community.',
    'aboutCommunityBody': 'Every farm has a story. By making it easier to discover local growers, we help those stories reach a little further.',
    'aboutSimpleTitle': 'Simple by nature.',
    'aboutSimpleBody': 'Fresh produce. Clear information. People you can get to know. We believe a good food experience starts with the essentials.',
    'aboutFooterBrand': 'HarvestHub',
    'aboutFooterTagline': 'Fresh from farms. Closer to you.',
    'contactEmail': '',
    'contactPhone': '',
  };
}

class PublicContentRepository {
  DocumentReference<Map<String, dynamic>> get _document =>
      FirebaseFirestore.instance.doc('appConfig/public');

  Future<PublicContent> load() async =>
      PublicContent.fromData((await _document.get()).data());

  Stream<PublicContent> watch() => _document.snapshots().map(
    (snapshot) => PublicContent.fromData(snapshot.data()),
  );

  Future<void> publish(PublicContent content) => _document.set({
    ...content.values,
    'aboutVersion': 1,
    'updatedAt': FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));
}
