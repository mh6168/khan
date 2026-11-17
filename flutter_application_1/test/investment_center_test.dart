import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/models/investment.dart';

void main() {
  test('LIRA purchase and buyback prices use the correct premiums', () {
    const liraSpot = 14500;
    final prices = InvestmentPrices.fromSpot(liraSpot);

    expect(prices.purchaseMinor, 15000);
    expect(prices.buybackMinor, 14600);
  });

  test('PARA purchase and buyback prices use the correct premiums', () {
    const paraSpot = 4200;
    final prices = InvestmentPrices.fromSpot(paraSpot);

    expect(prices.purchaseMinor, 4700);
    expect(prices.buybackMinor, 4300);
  });

  test('portfolio value uses buyback prices', () {
    const liraQuantity = 20;
    const paraQuantity = 50;
    final lira = InvestmentPrices.fromSpot(14500);
    final para = InvestmentPrices.fromSpot(4200);

    final valueMinor =
        liraQuantity * lira.buybackMinor + paraQuantity * para.buybackMinor;

    expect(valueMinor, 507000);
  });

  test('purchase totals use purchase prices', () {
    final lira = InvestmentPrices.fromSpot(14500);
    final para = InvestmentPrices.fromSpot(4200);

    expect(10 * lira.purchaseMinor, 150000);
    expect(10 * para.purchaseMinor, 47000);
  });
}
