import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/screens/customer_home_screen.dart';
import 'package:flutter_application_1/screens/investment_purchase_screen.dart';

void main() {
  testWidgets('Investment Center tab shows its demo dashboard', (
    tester,
  ) async {
    for (final size in [const Size(320, 568), const Size(1200, 900)]) {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(NavigationDestination).at(1));
      await tester.pumpAndSettle();

      expect(find.text('Investment Center'), findsNWidgets(2));
      expect(
        find.text('Explore new ways to invest in precious metals.'),
        findsOneWidget,
      );
      expect(find.text('LIRA'), findsWidgets);
      expect(find.text('PARA'), findsWidgets);
      expect(find.text('Portfolio overview'), findsNothing);
      expect(find.text('Performance'), findsOneWidget);
      expect(find.text('Recent activity'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('purchase preview is clearly non-transactional', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(const MaterialApp(home: CustomerHomeScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Investment Center'));
    await tester.pumpAndSettle();
    final buyButton = find.text('Buy LIRA');
    await tester.ensureVisible(buyButton);
    await tester.tap(buyButton);
    await tester.pumpAndSettle();

    expect(find.byType(InvestmentPurchaseScreen), findsOneWidget);
    expect(find.text('Purchase preview'), findsOneWidget);
    expect(find.text('Estimated total · demo'), findsOneWidget);
    expect(find.text('Continue · demo only'), findsOneWidget);
    expect(find.text('EGP 1,450.00'), findsOneWidget);

    await tester.tap(find.text('PARA'));
    await tester.pumpAndSettle();
    expect(find.text('EGP 42.00'), findsOneWidget);
    expect(find.text('EGP 420.00'), findsOneWidget);

    await tester.tap(find.text('Continue · demo only'));
    await tester.pumpAndSettle();
    expect(find.text('Demonstration only'), findsOneWidget);
    expect(find.textContaining('No order has been placed'), findsOneWidget);
    expect(find.text('Purchase successful'), findsNothing);
    await tester.binding.setSurfaceSize(null);
  });
}
