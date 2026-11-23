import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/sample_jewelry.dart';
import 'package:flutter_application_1/models/jewelry_category.dart';
import 'package:flutter_application_1/screens/customer_home_screen.dart';
import 'package:flutter_application_1/widgets/category_card.dart';
import 'package:flutter_application_1/widgets/product_card.dart';

void main() {
  testWidgets('homepage categories fit phone and tablet widths', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(1200, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(
        MaterialApp(
          home: CustomerHomeScreen(productsFuture: Future.value(sampleJewelry)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Investment Center'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(CategoryCard), findsNWidgets(6));
      expect(find.text('Trending jewelry'), findsOneWidget);
      expect(find.text('New arrivals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('all categories open their matching listing and return home', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(productsFuture: Future.value(sampleJewelry)),
      ),
    );

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('No jewelry available in this category yet.'),
      findsNothing,
    );
    const categoryProductNames = {
      JewelryCategory.rings: 'Nile Light Ring',
      JewelryCategory.necklaces: 'Moonlit Chain',
      JewelryCategory.bracelets: 'Cairo Links',
      JewelryCategory.earrings: 'Desert Bloom',
      JewelryCategory.pendants: 'Lotus Pendant',
      JewelryCategory.watches: 'Heritage Watch',
    };

    for (final category in JewelryCategory.values) {
      final categoryCard = find.byWidgetPredicate(
        (widget) => widget is CategoryCard && widget.category == category,
      );
      expect(categoryCard, findsOneWidget);
      await tester.ensureVisible(categoryCard);
      await tester.tap(categoryCard);
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.text(category.label),
        ),
        findsOneWidget,
      );
      expect(find.text(categoryProductNames[category]!), findsOneWidget);
      expect(find.byType(ProductCard), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('favorites can be saved from the home product cards', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(productsFuture: Future.value(sampleJewelry)),
      ),
    );
    await tester.pumpAndSettle();

    final favoriteButton = find.byTooltip('Add to favorites').first;
    await tester.ensureVisible(favoriteButton);
    await tester.tap(favoriteButton);
    await tester.tap(find.text('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('My Favorites'), findsOneWidget);
    expect(find.text('Your saved jewelry collection.'), findsOneWidget);
    expect(find.text('Nile Light Ring'), findsOneWidget);
    expect(find.byTooltip('Remove from favorites'), findsOneWidget);

    await tester.tap(find.byTooltip('Remove from favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Your favorites collection is empty.'), findsOneWidget);
    expect(find.text('My Favorites'), findsOneWidget);

    final exploreButton = find.text('Explore jewelry');
    await tester.ensureVisible(exploreButton);
    await tester.tap(exploreButton);
    await tester.pumpAndSettle();

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Trending jewelry'), findsOneWidget);
  });
}
