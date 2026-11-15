import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/gold_price_service.dart';
import 'package:flutter_application_1/data/management_api.dart';
import 'package:flutter_application_1/data/supabase_storage.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';

void main() {
  test('calculates jewelry prices for supported gold karats', () {
    for (final entry in const <int, double>{
      24: 6000,
      22: 5500,
      21: 5250,
      18: 4500,
    }.entries) {
      expect(
        GoldPriceService.calculateJewelryPrice(
          goldWeight: 2,
          goldKarat: entry.key,
          currentPremium: 100,
          goldPrices: {entry.key: entry.value},
        ),
        closeTo(2 * (entry.value + 100), 0.001),
      );
    }
  });

  test('keeps watch prices separate from jewelry calculation', () {
    final product = JewelryProduct.fromFirestore('watch-1', {
      'productType': 'watch',
      'brand': 'Khan',
      'model': 'Classic',
      'price': 12500,
      'photoPaths': <String>[],
    });

    expect(product.priceEgp, 12500);
  });

  test('maps calculated jewelry price from Firestore fields', () {
    final product = JewelryProduct.fromFirestore(
      'jewelry-1',
      {
        'productType': 'jewelry',
        'title': 'Gold ring',
        'goldWeight': 2,
        'goldKarat': 21,
        'currentPremium': 150,
        'photoPaths': <String>[],
      },
      goldPrices: const {21: 5250},
    );

    expect(product.priceEgp, closeTo(2 * (5250 + 150), 0.001));
  });

  test('builds signed image endpoint URLs for one or multiple paths', () {
    expect(
      publicSupabaseImageUrls([
        'jewelers/jeweler-1/jewelry/photos/one.jpg',
        'jewelers/jeweler-1/jewelry/photos/two image.png',
      ]),
      [
        '$managementApiBaseUrl/product-image.php'
            '?path=jewelers%2Fjeweler-1%2Fjewelry%2Fphotos%2Fone.jpg',
        '$managementApiBaseUrl/product-image.php'
            '?path=jewelers%2Fjeweler-1%2Fjewelry%2Fphotos%2Ftwo+image.png',
      ],
    );
  });
}
