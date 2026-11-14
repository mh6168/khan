import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_application_1/models/jewelry_category.dart';
import 'package:flutter_application_1/screens/customer_home_screen.dart';

void main() {
  testWidgets('homepage categories fit phone and tablet widths', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(1200, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Rings'), findsOneWidget);
      expect(find.text('Watches'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('all categories open the shared empty listing and return home', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));

    expect(find.byType(TextField), findsOneWidget);
    expect(
      find.text('No jewelry available in this category yet.'),
      findsNothing,
    );

    for (final category in JewelryCategory.values) {
      expect(find.text(category.label), findsOneWidget);
      await tester.ensureVisible(find.text(category.label));
      await tester.tap(find.text(category.label));
      await tester.pumpAndSettle();

      expect(find.text(category.label), findsOneWidget);
      expect(
        find.text('No jewelry available in this category yet.'),
        findsOneWidget,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
    }
  });
}
