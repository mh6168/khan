import 'dart:async';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_application_1/data/investment_service.dart';
import 'package:flutter_application_1/models/investment_sell_request.dart';

void main() {
  group('Investment sell requests', () {
    late FakeFirebaseFirestore firestore;
    late InvestmentService customerService;

    setUp(() async {
      firestore = FakeFirebaseFirestore();
      customerService = InvestmentService(
        firestore: firestore,
        currentUserId: () => 'customer-1',
      );
      await firestore.collection('customerPortfolios').doc('customer-1').set({
        'liraQuantity': 10,
        'paraQuantity': 8,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      await firestore.collection('masterDealerInventory').doc('lira').set({
        'quantity': 20,
        'reserved': 2,
      });
      await firestore.collection('masterDealerInventory').doc('para').set({
        'quantity': 30,
        'reserved': 3,
      });
    });

    test(
      'creates an LIRA-only request with locked payout and reservation',
      () async {
        final requestId = await _createRequest(
          customerService,
          lira: 2,
          para: 0,
        );

        final request =
            (await firestore
                    .collection('masterDealerSellRequests')
                    .doc(requestId)
                    .get())
                .data()!;
        final portfolio =
            (await firestore
                    .collection('customerPortfolios')
                    .doc('customer-1')
                    .get())
                .data()!;

        expect(request['liraQuantity'], 2);
        expect(request['paraQuantity'], 0);
        expect(request['liraUnitPriceMinor'], 14600);
        expect(request['totalPayoutMinor'], 29200);
        expect(request['status'], 'processing');
        expect(portfolio['liraQuantity'], 10);
        expect(portfolio['reservedLiraQuantity'], 2);
        expect((await customerService.watchPortfolio().first).liraQuantity, 8);
      },
    );

    test('creates a PARA-only request with locked payout', () async {
      final requestId = await _createRequest(customerService, lira: 0, para: 3);
      final request =
          (await firestore
                  .collection('masterDealerSellRequests')
                  .doc(requestId)
                  .get())
              .data()!;

      expect(request['paraQuantity'], 3);
      expect(request['paraUnitPriceMinor'], 4300);
      expect(request['totalPayoutMinor'], 12900);
    });

    test('creates a combined request with the exact quoted total', () async {
      final requestId = await _createRequest(customerService, lira: 2, para: 3);
      final request =
          (await firestore
                  .collection('masterDealerSellRequests')
                  .doc(requestId)
                  .get())
              .data()!;

      expect(request['totalPayoutMinor'], 2 * 14600 + 3 * 4300);
      expect(request['instapayPhone'], '01012345678');
    });

    test('rejects invalid Egyptian phone numbers', () async {
      await expectLater(
        customerService.createSellRequest(
          liraQuantity: 1,
          paraQuantity: 0,
          instapayPhone: '12345',
          liraUnitPriceMinor: 14600,
          paraUnitPriceMinor: 4300,
          customerName: 'Customer',
          customerEmail: 'customer@example.com',
          customerPhone: '',
        ),
        throwsArgumentError,
      );
      expect(
        InvestmentService.normalizeEgyptianMobile('+20 10 1234 5678'),
        '01012345678',
      );
      expect(
        InvestmentService.normalizeEgyptianMobile('0020-11-1234-5678'),
        '01112345678',
      );
    });

    test('rejects zero or negative quantities', () async {
      for (final (lira, para) in [(0, 0), (-1, 0), (0, -1)]) {
        await expectLater(
          _createRequest(customerService, lira: lira, para: para),
          throwsArgumentError,
        );
      }
    });

    test(
      'rejects quantities exceeding holdings or overlapping reservations',
      () async {
        await expectLater(
          _createRequest(customerService, lira: 11, para: 0),
          throwsStateError,
        );

        await _createRequest(customerService, lira: 7, para: 0);
        await expectLater(
          _createRequest(customerService, lira: 4, para: 0),
          throwsStateError,
        );
      },
    );

    test(
      'dealer transfer confirms once and updates holdings and inventory',
      () async {
        final requestId = await _createRequest(
          customerService,
          lira: 2,
          para: 3,
        );
        final dealerService = InvestmentService(
          firestore: firestore,
          currentUserId: () => 'dealer-1',
        );

        expect(
          await dealerService.markSellRequestMoneyTransferred(requestId),
          isTrue,
        );
        expect(
          await dealerService.markSellRequestMoneyTransferred(requestId),
          isFalse,
        );

        final request =
            (await firestore
                    .collection('masterDealerSellRequests')
                    .doc(requestId)
                    .get())
                .data()!;
        final portfolio =
            (await firestore
                    .collection('customerPortfolios')
                    .doc('customer-1')
                    .get())
                .data()!;
        final liraInventory =
            (await firestore
                    .collection('masterDealerInventory')
                    .doc('lira')
                    .get())
                .data()!;
        final paraInventory =
            (await firestore
                    .collection('masterDealerInventory')
                    .doc('para')
                    .get())
                .data()!;
        final transactions = await firestore
            .collection('masterDealerTransactions')
            .get();

        expect(request['status'], 'money_transferred');
        expect(request['transferredBy'], 'dealer-1');
        expect(request['transferredAt'], isNotNull);
        expect(portfolio['liraQuantity'], 8);
        expect(portfolio['paraQuantity'], 5);
        expect(portfolio['reservedLiraQuantity'], 0);
        expect(portfolio['reservedParaQuantity'], 0);
        expect(liraInventory['quantity'], 22);
        expect(liraInventory['reserved'], 2);
        expect(paraInventory['quantity'], 33);
        expect(paraInventory['reserved'], 3);
        expect(transactions.docs, hasLength(1));
        expect(transactions.docs.single.data()['type'], 'customer_buyback');
        final activity = await customerService.watchActivity().first;
        expect(
          activity.map((entry) => entry.unit),
          containsAll(['LIRA', 'PARA']),
        );
        expect(activity.every((entry) => entry.type == 'Buyback'), isTrue);
      },
    );

    test('customer request stream reflects dealer transfer status', () async {
      final iterator = StreamIterator(
        customerService.watchCustomerSellRequests(),
      );
      expect(await iterator.moveNext(), isTrue);
      expect(iterator.current, isEmpty);

      final requestId = await _createRequest(customerService, lira: 1, para: 0);
      expect(await iterator.moveNext(), isTrue);
      expect(
        iterator.current.single.status,
        InvestmentSellRequestStatus.processing,
      );

      await InvestmentService(
        firestore: firestore,
        currentUserId: () => 'dealer-1',
      ).markSellRequestMoneyTransferred(requestId);
      expect(await iterator.moveNext(), isTrue);
      expect(
        iterator.current.single.status,
        InvestmentSellRequestStatus.moneyTransferred,
      );
      await iterator.cancel();
    });
  });
}

Future<String> _createRequest(
  InvestmentService service, {
  required int lira,
  required int para,
}) {
  return service.createSellRequest(
    liraQuantity: lira,
    paraQuantity: para,
    instapayPhone: '01012345678',
    liraUnitPriceMinor: 14600,
    paraUnitPriceMinor: 4300,
    customerName: 'Customer One',
    customerEmail: 'customer@example.com',
    customerPhone: '01112345678',
  );
}
