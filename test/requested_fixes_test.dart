import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:untitled/src/features/common/data/models.dart';
import 'package:untitled/src/features/customer/customer.dart';
import 'package:untitled/src/features/common/management/operations.dart';
import 'package:untitled/src/features/common/markets/market_directory.dart';
import 'package:untitled/src/features/common/shared/components.dart';
import 'package:untitled/src/features/common/shared/theme.dart';

import 'fixtures/preview_store.dart';

void main() {
  for (final role in [UserRole.customer, UserRole.farmer]) {
    testWidgets(
      '${role.name} follow and heart update together on the farm page',
      (tester) async {
        final store = PreviewStore()..role = role;
        store.followed.clear();
        final farm = store.farms.first;
        await tester.pumpWidget(
          HarvestScope(
            store: store,
            child: MaterialApp(
              theme: Harvest.theme,
              home: FarmScreen(farm: farm),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Follow Farm'));
        await tester.pumpAndSettle();
        expect(store.isFollowed(farm.id), isTrue);
        expect(find.text('Following'), findsOneWidget);
        expect(find.byTooltip('Unfollow Farm'), findsOneWidget);
        await tester.tap(find.byTooltip('Unfollow Farm'));
        await tester.pumpAndSettle();
        expect(store.isFollowed(farm.id), isFalse);
        expect(find.text('Follow Farm'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets('new product has no selected sample image', (tester) async {
    final store = PreviewStore()..role = UserRole.farmer;
    await tester.pumpWidget(
      HarvestScope(
        store: store,
        child: MaterialApp(
          theme: Harvest.theme,
          home: const ProductEditorScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Add photo'), findsOneWidget);
    final photos = tester.widgetList<Photo>(find.byType(Photo));
    expect(photos.every((p) => p.asset.isEmpty && p.bytes == null), true);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'product details follow saves state and shows only the real photo',
    (tester) async {
      final store = PreviewStore();
      store.followed.clear();
      final product = store.products.first;
      store.products.removeWhere((p) => p.id != product.id);
      await tester.pumpWidget(
        HarvestScope(
          store: store,
          child: MaterialApp(
            theme: Harvest.theme,
            home: ProductScreen(product: product),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final photos = tester.widgetList<Photo>(find.byType(Photo));
      final actualImages = {product.image, store.farm(product.farmId).image};
      expect(photos.every((photo) => actualImages.contains(photo.asset)), true);
      await tester.ensureVisible(find.text('Follow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Follow'));
      await tester.pumpAndSettle();
      expect(store.isFollowed(product.farmId), true);
      expect(find.text('Following'), findsOneWidget);
      await tester.tap(find.text('Following'));
      await tester.pumpAndSettle();
      expect(store.isFollowed(product.farmId), false);
      expect(find.byTooltip('Notifications'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  test(
    'markets include real farm profiles and respect unpublished markets',
    () {
      final farms = PreviewStore().farms;
      final listings = marketListings([], farms);
      expect(listings.any((m) => m['name'] == farms.first.market), true);
      expect(listings.where((m) => m['name'] == farms.first.market).length, 1);
      final hidden = marketListings([
        {'name': farms.first.market, 'active': false},
      ], farms);
      expect(hidden.any((m) => m['name'] == farms.first.market), false);
      final published = marketListings([
        {'name': farms.first.market, 'active': true, 'hours': 'Sunday'},
      ], farms);
      expect(
        published.firstWhere((m) => m['name'] == farms.first.market)['hours'],
        'Sunday',
      );
    },
  );
}
