import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/common/data/public_content.dart';
import 'package:untitled/src/features/common/about_us/about_page.dart';
import 'package:untitled/src/features/admin/content/public_content_editor.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

import 'fixtures/preview_store.dart';
import 'test_support.dart';

class ContentFixture extends PublicContentRepository {
  PublicContent content = PublicContent.fromData(null);
  final updates = StreamController<PublicContent>.broadcast();
  int publishes = 0, loads = 0;
  @override
  Future<PublicContent> load() async {
    loads++;
    return content;
  }

  @override
  Stream<PublicContent> watch() async* {
    yield content;
    yield* updates.stream;
  }

  @override
  Future<void> publish(PublicContent value) async {
    publishes++;
    content = value;
    updates.add(value);
  }
}

Widget contentApp(Widget page, {UserRole role = UserRole.admin}) =>
    HarvestScope(
      store: PreviewStore()..role = role,
      child: MaterialApp(theme: Harvest.theme, home: page),
    );

void main() {
  setUpAll(loadHarvestFonts);
  test('existing and legacy About text share editable defaults', () {
    expect(
      PublicContent.fromData(null)['aboutHeadline'],
      'Good food starts\ncloser to home.',
    );
    expect(
      PublicContent.fromData({'about': ''})['about'],
      PublicContent.defaults['about'],
    );
    expect(
      PublicContent.fromData({'about': 'Previously published story'})['about'],
      'Previously published story',
    );
    expect(
      PublicContent.fromData({
        'aboutVersion': 1,
        'aboutCommunityBody': '',
      })['aboutCommunityBody'],
      isEmpty,
    );
  });

  testWidgets(
    'admin previews and publishes a draft; About replaces defaults and updates live',
    (tester) async {
      final repository = ContentFixture();
      addTearDown(repository.updates.close);
      await tester.pumpWidget(
        contentApp(PublicContentEditor(repository: repository)),
      );
      await tester.pumpAndSettle();
      final headline = find.byKey(const ValueKey('aboutHeadline'));
      await tester.scrollUntilVisible(
        headline,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(headline, 'Our local story');
      final story = find.byKey(const ValueKey('about'));
      await tester.scrollUntilVisible(
        story,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(story, 'A newly published story from our team.');
      await tester.scrollUntilVisible(
        find.text('Preview About page'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Preview About page'));
      await tester.pumpAndSettle();
      expect(find.text('Our local story'), findsOneWidget);
      expect(repository.publishes, 0);
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Publish content'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Publish content'));
      await tester.pumpAndSettle();
      expect(repository.publishes, 1);
      expect(
        (await repository.load())['about'],
        'A newly published story from our team.',
      );

      await tester.pumpWidget(
        contentApp(
          AboutScreen(repository: repository),
          role: UserRole.customer,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Our local story'), findsOneWidget);
      expect(find.text(PublicContent.defaults['aboutHeadline']!), findsNothing);
      await repository.publish(
        PublicContent.fromData({
          ...repository.content.values,
          'aboutVersion': 1,
          'aboutHeadline': 'Updated while reading',
          'aboutImage': '',
        }),
      );
      await tester.pumpAndSettle();
      expect(find.text('Updated while reading'), findsOneWidget);
      expect(find.text('Our local story'), findsNothing);
      expect(find.byType(Photo), findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'a required field cannot be emptied and published from below the viewport',
    (tester) async {
      final repository = ContentFixture();
      addTearDown(repository.updates.close);
      await tester.pumpWidget(
        contentApp(PublicContentEditor(repository: repository)),
      );
      await tester.pumpAndSettle();
      final headline = find.byKey(const ValueKey('aboutHeadline'));
      await tester.scrollUntilVisible(
        headline,
        350,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.enterText(headline, '');
      await tester.scrollUntilVisible(
        find.text('Publish content'),
        500,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Publish content'));
      await tester.pumpAndSettle();
      expect(repository.publishes, 0);
      expect(find.text('Main headline is required.'), findsOneWidget);
    },
  );

  testWidgets('non-admin cannot load or publish public content', (
    tester,
  ) async {
    final repository = ContentFixture();
    addTearDown(repository.updates.close);
    await tester.pumpWidget(
      contentApp(
        PublicContentEditor(repository: repository),
        role: UserRole.farmer,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Administrator access required.'), findsOneWidget);
    expect(repository.loads, 0);
    expect(repository.publishes, 0);
  });
}
