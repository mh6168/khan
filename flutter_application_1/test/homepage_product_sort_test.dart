import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/khan_colors.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';
import 'package:flutter_application_1/screens/customer_home_screen.dart';
import 'package:flutter_application_1/widgets/home_sections.dart';
import 'package:flutter_application_1/widgets/product_sort_control.dart';

void main() {
  const products = [
    JewelryProduct(
      id: 'gold-ring',
      name: 'Gold Ring',
      category: 'Rings',
      priceEgp: 500,
      artworkIcon: Icons.diamond_outlined,
      artworkColor: khanDark,
    ),
    JewelryProduct(
      id: 'silver-ring',
      name: 'Silver Ring',
      category: 'Rings',
      priceEgp: 100,
      artworkIcon: Icons.diamond_outlined,
      artworkColor: khanDark,
    ),
    JewelryProduct(
      id: 'pearl-ring',
      name: 'Pearl Ring',
      category: 'Rings',
      priceEgp: 300,
      artworkIcon: Icons.diamond_outlined,
      artworkColor: khanDark,
    ),
  ];

  testWidgets('homepage search and price sorting preserve each other', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CustomerHomeScreen(productsFuture: Future.value(products)),
      ),
    );
    await tester.pumpAndSettle();

    expect(_firstProductSectionNames(tester), [
      'Gold Ring',
      'Silver Ring',
      'Pearl Ring',
    ]);

    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Ring');
    await tester.pumpAndSettle();
    expect(_firstProductSectionNames(tester), [
      'Gold Ring',
      'Silver Ring',
      'Pearl Ring',
    ]);

    await _selectSort(tester, ProductSortOption.priceLowToHigh);
    expect(_firstProductSectionNames(tester), [
      'Silver Ring',
      'Pearl Ring',
      'Gold Ring',
    ]);
    expect(_searchText(tester), 'Ring');

    await tester.enterText(searchField, 'Pearl');
    await tester.pumpAndSettle();
    expect(_firstProductSectionNames(tester), ['Pearl Ring']);
    expect(_selectedSort(tester), ProductSortOption.priceLowToHigh);

    await tester.enterText(searchField, 'Ring');
    await tester.pumpAndSettle();
    await _selectSort(tester, ProductSortOption.priceHighToLow);
    expect(_firstProductSectionNames(tester), [
      'Gold Ring',
      'Pearl Ring',
      'Silver Ring',
    ]);
    expect(_searchText(tester), 'Ring');

    await _selectSort(tester, ProductSortOption.recommended);
    expect(_firstProductSectionNames(tester), [
      'Gold Ring',
      'Silver Ring',
      'Pearl Ring',
    ]);
  });
}

Future<void> _selectSort(WidgetTester tester, ProductSortOption option) async {
  final control = find.byType(DropdownButton<ProductSortOption>);
  await tester.ensureVisible(control);
  await tester.tap(control);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option.label).last);
  await tester.pumpAndSettle();
}

ProductSortOption _selectedSort(WidgetTester tester) {
  return tester
      .widget<DropdownButton<ProductSortOption>>(
        find.byType(DropdownButton<ProductSortOption>),
      )
      .value!;
}

List<String> _firstProductSectionNames(WidgetTester tester) {
  return tester
      .widgetList<HomeProductSection>(find.byType(HomeProductSection))
      .first
      .products
      .map((product) => product.name)
      .toList();
}

String _searchText(WidgetTester tester) {
  return tester.widget<EditableText>(find.byType(EditableText)).controller.text;
}
