import 'dart:convert';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:flutter_application_1/data/investment_service.dart';
import 'package:flutter_application_1/data/paymob_service.dart';
import 'package:flutter_application_1/screens/paymob_return_screen.dart';

void main() {
  group('PaymobService', () {
    test('creates an order, payment key, and iframe checkout URL', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        switch (request.url.path) {
          case '/api/auth/tokens':
            return http.Response('{"token":"auth-token"}', 200);
          case '/api/ecommerce/orders':
            return http.Response('{"id":456}', 201);
          case '/api/acceptance/payment_keys':
            return http.Response('{"token":"checkout-token"}', 201);
          default:
            return http.Response('Not found', 404);
        }
      });

      final session = await _paymob(client).createCheckoutSession(
        amountMinor: 12500,
        merchantOrderId: 'khan-md-order-1',
        email: 'customer@example.com',
        returnUrl: 'https://demo.example/?khan_order_id=order-1',
      );

      expect(requests.map((request) => request.url.path), [
        '/api/auth/tokens',
        '/api/ecommerce/orders',
        '/api/acceptance/payment_keys',
      ]);
      final order = jsonDecode(requests[1].body) as Map<String, dynamic>;
      expect(order['amount_cents'], 12500);
      expect(order['merchant_order_id'], 'khan-md-order-1');
      final paymentKey = jsonDecode(requests[2].body) as Map<String, dynamic>;
      expect(paymentKey['order_id'], 456);
      expect(paymentKey['integration_id'], 1234);
      expect(paymentKey['expiration'], 900);
      expect(
        paymentKey['redirection_url'],
        'https://demo.example/?khan_order_id=order-1',
      );
      expect(session.paymobOrderId, '456');
      expect(
        session.checkoutUrl.toString(),
        'https://accept.paymob.com/api/acceptance/iframes/5678'
        '?payment_token=checkout-token',
      );
    });

    test(
      'verifies a successful payment against amount and merchant order',
      () async {
        final client = MockClient((request) async {
          if (request.url.path.endsWith('/auth/tokens')) {
            return http.Response('{"token":"auth-token"}', 200);
          }
          if (request.url.path.endsWith('/acceptance/transactions/345')) {
            return http.Response(
              jsonEncode({
                'success': true,
                'pending': false,
                'currency': 'EGP',
                'amount_cents': 12500,
                'order': {'merchant_order_id': 'khan-md-order-1'},
              }),
              200,
            );
          }
          return http.Response('Not found', 404);
        });

        final result = await _paymob(client).verifyTransaction(
          transactionId: '345',
          expectedMerchantOrderId: 'khan-md-order-1',
          expectedAmountMinor: 12500,
        );

        expect(result.status, PaymobVerificationStatus.success);
        expect(result.payment?.transactionId, '345');
      },
    );

    test(
      'reports pending and unsuccessful transactions without confirming',
      () async {
        Future<PaymobVerificationResult> verify(Map<String, dynamic> body) {
          return _paymob(
            MockClient((request) async {
              if (request.url.path.endsWith('/auth/tokens')) {
                return http.Response('{"token":"auth-token"}', 200);
              }
              return http.Response(jsonEncode(body), 200);
            }),
          ).verifyTransaction(
            transactionId: '345',
            expectedMerchantOrderId: 'khan-md-order-1',
            expectedAmountMinor: 12500,
          );
        }

        final pending = await verify({'success': false, 'pending': true});
        final failed = await verify({'success': false, 'pending': false});

        expect(pending.status, PaymobVerificationStatus.pending);
        expect(failed.status, PaymobVerificationStatus.failed);
      },
    );

    test('rejects a successful transaction with a mismatched amount', () async {
      final client = MockClient((request) async {
        if (request.url.path.endsWith('/auth/tokens')) {
          return http.Response('{"token":"auth-token"}', 200);
        }
        return http.Response(
          jsonEncode({
            'success': true,
            'pending': false,
            'currency': 'EGP',
            'amount_cents': 100,
            'order': {'merchant_order_id': 'khan-md-order-1'},
          }),
          200,
        );
      });

      await expectLater(
        _paymob(client).verifyTransaction(
          transactionId: '345',
          expectedMerchantOrderId: 'khan-md-order-1',
          expectedAmountMinor: 12500,
        ),
        throwsA(isA<PaymobException>()),
      );
    });
  });

  group('InvestmentService checkout records', () {
    late FakeFirebaseFirestore firestore;
    late InvestmentService service;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      service = InvestmentService(
        firestore: firestore,
        currentUserId: () => 'customer-1',
      );
      await firestore.collection('masterDealerInventory').doc('lira').set({
        'asset': 'lira',
        'quantity': 8,
        'reserved': 0,
      });
      await firestore.collection('masterDealerInventory').doc('para').set({
        'asset': 'para',
        'quantity': 20,
        'reserved': 0,
      });
    });

    test('updates holdings and transaction history once per payment', () async {
      final orderId = await service.createPendingPurchase(
        unit: 'lira',
        quantity: 2,
        unitPriceMinor: 15000,
      );
      await service.attachPaymobOrder(orderId: orderId, paymobOrderId: '456');
      final payment = VerifiedPaymobPayment(
        transactionId: '345',
        amountMinor: 30000,
        merchantOrderId: 'khan-md-$orderId',
      );

      expect(
        await service.completePurchase(orderId: orderId, payment: payment),
        isTrue,
      );
      expect(
        await service.completePurchase(orderId: orderId, payment: payment),
        isFalse,
      );
      final inventory =
          (await firestore
                  .collection('masterDealerInventory')
                  .doc('lira')
                  .get())
              .data()!;
      final order =
          (await firestore
                  .collection('masterDealerPurchaseOrders')
                  .doc(orderId)
                  .get())
              .data()!;
      final portfolio =
          (await firestore
                  .collection('customerPortfolios')
                  .doc('customer-1')
                  .get())
              .data()!;
      final transactions = await firestore
          .collection('masterDealerTransactions')
          .get();

      expect(inventory['quantity'], 6);
      expect(inventory['reserved'], 0);
      expect(order['status'], 'completed');
      expect(portfolio['liraQuantity'], 2);
      expect(portfolio['paraQuantity'], 0);
      expect(transactions.docs, hasLength(1));
      expect(transactions.docs.single.data()['amountMinorUnits'], 30000);
    });

    test(
      'cancellation releases the reservation without recording a purchase',
      () async {
        final orderId = await service.createPendingPurchase(
          unit: 'para',
          quantity: 3,
          unitPriceMinor: 4700,
        );

        await service.cancelPurchase(orderId);

        final inventory =
            (await firestore
                    .collection('masterDealerInventory')
                    .doc('para')
                    .get())
                .data()!;
        final order =
            (await firestore
                    .collection('masterDealerPurchaseOrders')
                    .doc(orderId)
                    .get())
                .data()!;
        expect(inventory['reserved'], 0);
        expect(order['status'], 'cancelled');
        expect(
          (await firestore.collection('masterDealerTransactions').get()).docs,
          isEmpty,
        );
      },
    );
  });

  group('Paymob automatic return', () {
    test('parses transaction data without trusting browser success flags', () {
      final callback = PaymobReturnData.fromUri(
        Uri.parse(
          'https://demo.example/?khan_order_id=order_1&id=345&success=false',
        ),
      );

      expect(callback?.orderId, 'order_1');
      expect(callback?.transactionId, '345');
      expect(callback?.wasCancelled, isFalse);
    });

    testWidgets('verifies payment and completes the purchase automatically', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final investments = InvestmentService(
        firestore: firestore,
        currentUserId: () => 'customer-1',
      );
      await firestore.collection('masterDealerInventory').doc('lira').set({
        'quantity': 8,
        'reserved': 0,
      });
      final orderId = await investments.createPendingPurchase(
        unit: 'lira',
        quantity: 2,
        unitPriceMinor: 12500,
      );
      final paymob = _paymob(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/tokens')) {
            return http.Response('{"token":"auth-token"}', 200);
          }
          return http.Response(
            jsonEncode({
              'success': true,
              'pending': false,
              'currency': 'EGP',
              'amount_cents': 25000,
              'order': {'merchant_order_id': 'khan-md-$orderId'},
            }),
            200,
          );
        }),
      );
      final callback = PaymobReturnData.fromUri(
        Uri.parse(
          'https://demo.example/?khan_order_id=$orderId&id=345&success=false',
        ),
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: PaymobReturnScreen(
            callback: callback,
            customerId: 'customer-1',
            investmentService: investments,
            paymobService: paymob,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Purchase successful'), findsNWidgets(2));
      final portfolio =
          (await firestore
                  .collection('customerPortfolios')
                  .doc('customer-1')
                  .get())
              .data()!;
      expect(portfolio['liraQuantity'], 2);
      expect(
        (await firestore.collection('masterDealerTransactions').get()).docs,
        hasLength(1),
      );
    });

    testWidgets('failed verification releases inventory without crediting', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final investments = InvestmentService(
        firestore: firestore,
        currentUserId: () => 'customer-1',
      );
      await firestore.collection('masterDealerInventory').doc('para').set({
        'quantity': 8,
        'reserved': 0,
      });
      final orderId = await investments.createPendingPurchase(
        unit: 'para',
        quantity: 2,
        unitPriceMinor: 12500,
      );
      final paymob = _paymob(
        MockClient((request) async {
          if (request.url.path.endsWith('/auth/tokens')) {
            return http.Response('{"token":"auth-token"}', 200);
          }
          return http.Response('{"success":false,"pending":false}', 200);
        }),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: PaymobReturnScreen(
            callback: PaymobReturnData(
              orderId: orderId,
              transactionId: '345',
              wasCancelled: false,
            ),
            customerId: 'customer-1',
            investmentService: investments,
            paymobService: paymob,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Payment not verified'), findsOneWidget);
      expect(
        (await firestore.collection('customerPortfolios').get()).docs,
        isEmpty,
      );
      expect(
        (await firestore.collection('masterDealerTransactions').get()).docs,
        isEmpty,
      );
      final inventory =
          (await firestore
                  .collection('masterDealerInventory')
                  .doc('para')
                  .get())
              .data()!;
      expect(inventory['reserved'], 0);
    });

    testWidgets('cancelled callback releases its reservation without credit', (
      tester,
    ) async {
      final firestore = FakeFirebaseFirestore();
      final investments = InvestmentService(
        firestore: firestore,
        currentUserId: () => 'customer-1',
      );
      await firestore.collection('masterDealerInventory').doc('para').set({
        'quantity': 8,
        'reserved': 0,
      });
      final orderId = await investments.createPendingPurchase(
        unit: 'para',
        quantity: 1,
        unitPriceMinor: 12500,
      );
      final callback = PaymobReturnData.fromUri(
        Uri.parse(
          'https://demo.example/?khan_order_id=$orderId&cancelled=true',
        ),
      )!;

      await tester.pumpWidget(
        MaterialApp(
          home: PaymobReturnScreen(
            callback: callback,
            customerId: 'customer-1',
            investmentService: investments,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Purchase cancelled'), findsOneWidget);
      expect(
        (await firestore.collection('customerPortfolios').get()).docs,
        isEmpty,
      );
      final inventory =
          (await firestore
                  .collection('masterDealerInventory')
                  .doc('para')
                  .get())
              .data()!;
      expect(inventory['reserved'], 0);
    });
  });
}

PaymobService _paymob(http.Client client) {
  return PaymobService(
    client: client,
    apiKey: 'test-api-key',
    integrationId: '1234',
    iframeId: '5678',
    apiBaseUrl: 'https://accept.paymob.com/api',
    redirectUrl: 'https://demo.example/return',
    timeoutSeconds: 2,
  );
}
