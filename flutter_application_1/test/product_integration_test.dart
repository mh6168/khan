import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/gold_price_service.dart';
import 'package:flutter_application_1/data/supabase_storage.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';
import 'package:flutter_application_1/models/jewelry_reservation.dart';

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

  test('only available jewelry products can be reserved', () {
    final available = JewelryProduct.fromFirestore('jewelry-available', {
      'productType': 'jewelry',
      'title': 'Available ring',
      'availability': 'available',
    });
    final reserved = JewelryProduct.fromFirestore('jewelry-reserved', {
      'productType': 'jewelry',
      'title': 'Reserved ring',
      'availability': 'unavailable',
    });

    expect(available.canReserve, isTrue);
    expect(reserved.canReserve, isFalse);
  });

  test('available watches can be reserved', () {
    final watch = JewelryProduct.fromFirestore('watch-reservable', {
      'productType': 'watch',
      'brand': 'Rolex',
      'model': 'Classic',
      'price': 12500,
      'availability': 'available',
    });

    expect(watch.canReserve, isTrue);
  });

  test('maps all customer-facing reservation statuses', () {
    String labelFor(String status) {
      return JewelryReservation(
        id: 'reservation-1',
        customerUid: 'customer-1',
        productId: 'product-1',
        productName: 'Ring',
        jewelerId: 'jeweler-1',
        jewelerStoreName: 'Khan Store',
        originalTotalPriceMinorUnits: 10000,
        depositAmountMinorUnits: 1000,
        remainingBalanceMinorUnits: 9000,
        status: status,
        createdAt: DateTime(2026),
        expiresAt: DateTime(2026, 1, 3),
      ).statusLabel;
    }

    expect(labelFor('reserved_for_48_hours'), 'Reserved for 48 hours');
    expect(labelFor('handed_to_user'), 'Handed to you');
    expect(labelFor('refunded_deposit'), 'Deposit refunded');
    expect(labelFor('user_didnt_pick_up'), 'Not collected');
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
