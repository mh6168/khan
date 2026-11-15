import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/gold_price_service.dart';
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

  test('builds public URLs for one or multiple Supabase image paths', () {
    expect(
      [
        publicSupabaseImageUrl(
          'jewelers/jeweler-1/jewelry/photos/one.jpg',
          baseUrl: 'https://example.supabase.co',
          bucket: 'jeweler-documents',
        ),
        publicSupabaseImageUrl(
          'jewelers/jeweler-1/jewelry/photos/two image.png',
          baseUrl: 'https://example.supabase.co',
          bucket: 'jeweler-documents',
        ),
      ],
      [
        'https://example.supabase.co/storage/v1/object/public/'
            'jeweler-documents/jewelers/jeweler-1/jewelry/photos/one.jpg',
        'https://example.supabase.co/storage/v1/object/public/'
            'jeweler-documents/jewelers/jeweler-1/jewelry/photos/two%20image.png',
      ],
    );
  });
}
