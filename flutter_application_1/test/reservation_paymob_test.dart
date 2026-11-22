import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/data/paymob_service.dart';
import 'package:flutter_application_1/data/reservation_service.dart';
import 'package:flutter_application_1/models/jeweler_profile.dart';
import 'package:flutter_application_1/models/jewelry_product.dart';

void main() {
  late FakeFirebaseFirestore firestore;
  late ReservationService service;
  late JewelryProduct product;
  late JewelerProfile jeweler;
  late ReservationQuote quote;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    service = ReservationService(
      firestore: firestore,
      currentUserId: () => 'customer-1',
    );
    product = JewelryProduct.fromFirestore('watch-1', {
      'productType': 'watch',
      'brand': 'KHAN',
      'model': 'Classic',
      'price': 50000,
      'jewelerId': 'jeweler-1',
      'availability': 'available',
      'photoPaths': ['watch/photo.jpg'],
    });
    jeweler = JewelerProfile.fromFirestore('jeweler-1', {
      'status': 'approved',
      'storeName': 'KHAN Store',
    });
    quote = ReservationQuote.fromProduct(product, jeweler);
    await firestore.collection('users').doc('customer-1').set({
      'name': 'Customer One',
      'email': 'customer@example.com',
      'phone': '01000000000',
    });
    await firestore.collection('products').doc(product.id).set({
      'productType': 'watch',
      'brand': 'KHAN',
      'model': 'Classic',
      'price': 50000,
      'jewelerId': 'jeweler-1',
      'availability': 'available',
      'photoPaths': ['watch/photo.jpg'],
    });
  });

  test('calculates a 10% deposit from the current product price', () {
    expect(quote.totalMinor, 5000000);
    expect(quote.depositMinor, 500000);
    expect(quote.remainingMinor, 4500000);
  });

  test('uses the existing Paymob service to start the deposit checkout', () async {
    final requests = <http.Request>[];
    final paymob = PaymobService(
      client: MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/auth/tokens':
            return http.Response('{"token":"test-auth-token"}', 200);
          case '/api/ecommerce/orders':
            return http.Response('{"id":456}', 201);
          case '/api/acceptance/payment_keys':
            return http.Response('{"token":"test-payment-token"}', 201);
          default:
            return http.Response('Not found', 404);
        }
      }),
      apiKey: 'test-api-key',
      integrationId: '1234',
      iframeId: '5678',
      apiBaseUrl: 'https://accept.paymob.com/api',
    );

    final session = await paymob.createCheckoutSession(
      amountMinor: quote.depositMinor,
      merchantOrderId: 'khan-rsv-order-1',
      email: 'customer@example.com',
      returnUrl: 'https://khan.example/?khan_reservation_order_id=order-1',
    );

    final order = jsonDecode(requests[1].body) as Map<String, dynamic>;
    expect(order['amount_cents'], 500000);
    expect(order['merchant_order_id'], 'khan-rsv-order-1');
    expect(
      session.checkoutUrl.toString(),
      'https://accept.paymob.com/api/acceptance/iframes/5678'
      '?payment_token=test-payment-token',
    );
  });

  test('creates a Firestore reservation once after verified payment', () async {
    final checkout = await service.createCheckout(
      product: product,
      quote: quote,
      customerName: 'Customer One',
      customerEmail: 'customer@example.com',
      customerPhone: '01000000000',
    );
    await service.attachPaymobOrder(
      orderId: checkout.orderId,
      paymobOrderId: 'paymob-order-1',
    );

    final payment = VerifiedPaymobPayment(
      transactionId: '12345',
      amountMinor: checkout.depositMinor,
      merchantOrderId: checkout.merchantOrderId,
    );
    expect(
      await service.completePayment(
        orderId: checkout.orderId,
        payment: payment,
      ),
      isTrue,
    );
    expect(
      await service.completePayment(
        orderId: checkout.orderId,
        payment: payment,
      ),
      isFalse,
    );

    final reservation =
        (await firestore
                .collection('jewelryReservations')
                .doc(checkout.orderId)
                .get())
            .data()!;
    expect(reservation['status'], 'reserved_for_48_hours');
    expect(reservation['customerUid'], 'customer-1');
    expect(reservation['productId'], 'watch-1');
    expect(reservation['jewelerId'], 'jeweler-1');
    expect(reservation['depositAmountMinorUnits'], 500000);
    expect(reservation['paymobTransactionId'], '12345');
    final createdAt = reservation['reservationCreatedAt'] as Timestamp;
    final expiresAt = reservation['reservationExpiresAt'] as Timestamp;
    expect(
      (expiresAt.toDate().difference(createdAt.toDate()).inSeconds - 48 * 3600)
          .abs(),
      lessThanOrEqualTo(2),
    );
  });

  test('a pending checkout prevents a second customer reservation', () async {
    await service.createCheckout(product: product, quote: quote);

    await expectLater(
      service.createCheckout(product: product, quote: quote),
      throwsA(isA<StateError>()),
    );
  });

  test('cancelling checkout releases the product lock', () async {
    final checkout = await service.createCheckout(
      product: product,
      quote: quote,
    );
    await service.cancelCheckout(checkout.orderId);

    final productSnapshot = await firestore
        .collection('products')
        .doc(product.id)
        .get();
    expect(productSnapshot.data()?['availability'], 'available');
    expect(
      productSnapshot.data()?.containsKey('reservationLockOrderId'),
      isFalse,
    );
  });

  test('marks expired reservations as not collected in My Orders', () async {
    final expiredAt = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(minutes: 1)),
    );
    await firestore
        .collection('jewelryReservations')
        .doc('old-reservation')
        .set({
          'customerUid': 'customer-1',
          'productId': 'watch-1',
          'productName': 'KHAN Classic',
          'jewelerId': 'jeweler-1',
          'jewelerStoreName': 'KHAN Store',
          'originalTotalPriceMinorUnits': 5000000,
          'depositAmountMinorUnits': 500000,
          'remainingBalanceMinorUnits': 4500000,
          'status': 'reserved_for_48_hours',
          'createdAt': Timestamp.now(),
          'reservationCreatedAt': Timestamp.now(),
          'expiresAt': expiredAt,
          'reservationExpiresAt': expiredAt,
        });

    final reservations = await service.watchMyReservations('customer-1').first;

    expect(reservations.single.status, 'user_didnt_pick_up');
  });
}
