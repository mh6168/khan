import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/khan_colors.dart';
import 'package:flutter_application_1/models/jewelry_category.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';
import 'package:flutter_application_1/screens/category_listing_screen.dart';
import 'package:flutter_application_1/screens/customer_home_screen.dart';
import 'package:flutter_application_1/widgets/category_card.dart';
import 'package:flutter_application_1/widgets/product_card.dart';
import 'package:flutter_application_1/widgets/product_sort_control.dart';

void main() {
  final products = [
    _product(
      id: 'pendant-1',
      name: 'Golden Pendant',
      category: 'Pendants',
      price: 250,
    ),
    _product(
      id: 'pendant-2',
      name: 'Silver Pendant',
      category: 'Pendants',
      price: 80,
    ),
    _product(
      id: 'pendant-3',
      name: 'Mini Pendant',
      category: 'Pendants',
      price: double.nan,
    ),
    _product(id: 'ring-1', name: 'Golden Ring', category: 'Rings', price: 120),
    _product(
      id: 'watch-1',
      name: 'Heritage Watch',
      category: 'Watches',
      price: 500,
      productType: 'watch',
    ),
  ];

  testWidgets('category page filters by selected category and product name', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListingScreen(
          category: JewelryCategory.pendants,
          productsFuture: Future.value(products),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(AppBar), matching: find.text('Pendants')),
      findsOneWidget,
    );
    expect(find.text('Golden Pendant'), findsOneWidget);
    expect(find.text('Silver Pendant'), findsOneWidget);
    expect(find.text('Price unavailable'), findsOneWidget);
    expect(find.text('Golden Ring'), findsNothing);
    expect(find.text('Heritage Watch'), findsNothing);

    await tester.enterText(find.byType(TextField), 'gold');
    await tester.pumpAndSettle();

    expect(find.text('Golden Pendant'), findsOneWidget);
    expect(find.text('Silver Pendant'), findsNothing);
    expect(find.text('Golden Ring'), findsNothing);
  });

  testWidgets('sorts category products both ways and keeps search active', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListingScreen(
          category: JewelryCategory.pendants,
          productsFuture: Future.value(products),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _selectSort(tester, 'Price: Low to High');
    expect(_displayedProductNames(tester), [
      'Silver Pendant',
      'Golden Pendant',
      'Mini Pendant',
    ]);

    await tester.enterText(find.byType(TextField), 'pendant');
    await tester.pumpAndSettle();
    await _selectSort(tester, 'Price: High to Low');
    expect(_displayedProductNames(tester), [
      'Golden Pendant',
      'Silver Pendant',
      'Mini Pendant',
    ]);

    await tester.enterText(find.byType(TextField), 'gold');
    await tester.pumpAndSettle();
    expect(_displayedProductNames(tester), ['Golden Pendant']);
  });

  testWidgets('shows an empty state when category search has no matches', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryListingScreen(
          category: JewelryCategory.pendants,
          productsFuture: Future.value(products),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'platinum');
    await tester.pumpAndSettle();

    expect(find.text('No products match your search.'), findsOneWidget);
    expect(find.byType(ProductCard), findsNothing);
  });

  testWidgets('homepage navigation opens Pendants and Watches listings', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(productsFuture: Future.value(products)),
      ),
    );
    await tester.pumpAndSettle();

    await _openCategory(tester, JewelryCategory.pendants);
    expect(find.text('Golden Pendant'), findsOneWidget);
    expect(find.text('Heritage Watch'), findsNothing);

    await tester.pageBack();
    await tester.pumpAndSettle();
    await _openCategory(tester, JewelryCategory.watches);

    expect(find.text('Heritage Watch'), findsOneWidget);
    expect(find.text('Golden Pendant'), findsNothing);
  });
}

JewelryProduct _product({
  required String id,
  required String name,
  required String category,
  double? price,
  String productType = 'jewelry',
}) {
  return JewelryProduct(
    id: id,
    name: name,
    category: category,
    priceEgp: price,
    artworkIcon: Icons.diamond_outlined,
    artworkColor: khanDark,
    productType: productType,
  );
}

Future<void> _selectSort(WidgetTester tester, String label) async {
  await tester.tap(find.byType(DropdownButton<ProductSortOption>));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label).last);
  await tester.pumpAndSettle();
}

List<String> _displayedProductNames(WidgetTester tester) {
  return tester
      .widgetList<ProductCard>(find.byType(ProductCard))
      .map((card) => card.product.name)
      .toList();
}

Future<void> _openCategory(
  WidgetTester tester,
  JewelryCategory category,
) async {
  final card = find.byWidgetPredicate(
    (widget) => widget is CategoryCard && widget.category == category,
  );
  await tester.ensureVisible(card);
  await tester.tap(card);
  await tester.pumpAndSettle();
}
