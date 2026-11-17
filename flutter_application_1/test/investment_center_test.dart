import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/investment_price_service.dart';
import 'package:flutter_application_1/models/investment.dart';

void main() {
  test('fetches gold and silver from the EGP GoldAPI endpoints', () async {
    final requests = <http.Request>[];
    final client = MockClient((request) async {
      requests.add(request);
      final isGold = request.url.path.endsWith('/XAU/EGP');
      return http.Response(
        jsonEncode({
          'currency': 'EGP',
          'metal': isGold ? 'XAU' : 'XAG',
          if (isGold) 'price_gram_24k': 14500 else 'price_gram_925': 42,
        }),
        200,
      );
    });

    final prices = await InvestmentPriceService(
      client: client,
      apiKey: 'test-key',
    ).fetchPrices();

    expect(requests, hasLength(2));
    expect(
      requests.every(
        (request) => request.headers['x-access-token'] == 'test-key',
      ),
      isTrue,
    );
    expect(prices.lira.purchaseMinor, 15000);
    expect(prices.para.purchaseMinor, 4700);
  });

  test('GoldAPI EGP quotes calculate the LIRA and PARA prices', () {
    final prices = InvestmentPriceService.parseResponses(
      {'currency': 'EGP', 'metal': 'XAU', 'price_gram_24k': 14500},
      {'currency': 'EGP', 'metal': 'XAG', 'price_gram_925': 42},
    );

    expect(prices.lira.spotMinor, 14500);
    expect(prices.lira.purchaseMinor, 15000);
    expect(prices.lira.buybackMinor, 14600);
    expect(prices.para.spotMinor, 4200);
    expect(prices.para.purchaseMinor, 4700);
    expect(prices.para.buybackMinor, 4300);
  });

  test('pure silver quote is converted to 925 silver', () {
    final prices = InvestmentPriceService.parseResponses(
      {'currency': 'EGP', 'metal': 'XAU', 'price_gram_24k': 14500},
      {
        'currency': 'EGP',
        'metal': 'XAG',
        'price_per_unit': {'gram': 42},
      },
    );

    expect(prices.para.spotMinor, 3885);
  });

  test('quotes in currencies other than EGP are rejected', () {
    expect(
      () => InvestmentPriceService.parseResponses(
        {'currency': 'USD', 'metal': 'XAU', 'price_gram_24k': 14500},
        {'currency': 'EGP', 'metal': 'XAG', 'price_gram_925': 42},
      ),
      throwsFormatException,
    );
  });

  test('parses the actual GoldAPI XAG pure-silver gram field', () {
    final prices = InvestmentPriceService.parseResponses(
      {
        'currency': 'EGP',
        'metal': 'XAU',
        'unit': 'troy_ounce',
        'price': 206661.702,
        'price_per_unit': {'gram': 6643.2668},
        'melt_price_per_gram': {'24k': 6643.2668},
      },
      {
        'currency': 'EGP',
        'metal': 'XAG',
        'unit': 'troy_ounce',
        'price': 2538.8057,
        'price_per_unit': {'gram': 81.6176},
        'melt_price_per_gram': {'24k': 81.6176},
      },
    );

    expect(prices.lira.spotMinor, 6643);
    expect(prices.para.spotMinor, 7550);
    expect(prices.lira.purchaseMinor, 7143);
    expect(prices.para.purchaseMinor, 8050);
  });

  test(
    'converts GoldAPI troy-ounce quotes to grams when gram fields are absent',
    () {
      final prices = InvestmentPriceService.parseResponses(
        {
          'currency': 'EGP',
          'metal': 'XAU',
          'unit': 'troy_ounce',
          'price': 311.034768,
        },
        {
          'currency': 'EGP',
          'metal': 'XAG',
          'unit': 'troy_ounce',
          'price': 311.034768,
        },
      );

      expect(prices.lira.spotMinor, 10);
      expect(prices.para.spotMinor, 925);
    },
  );

  test('does not interpret an unsupported price unit as a troy ounce', () {
    expect(
      () => InvestmentPriceService.parseResponses(
        {'currency': 'EGP', 'metal': 'XAU', 'unit': 'gram', 'price': 100},
        {
          'currency': 'EGP',
          'metal': 'XAG',
          'price_per_unit': {'gram': 10},
        },
      ),
      throwsFormatException,
    );
  });

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
