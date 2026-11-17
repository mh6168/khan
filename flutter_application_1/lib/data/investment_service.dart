import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'paymob_service.dart';
import '../models/investment.dart';

class InvestmentService {
  InvestmentService({
    FirebaseFirestore? firestore,
    String? Function()? currentUserId,
  }) : firestore = firestore ?? FirebaseFirestore.instance,
       _currentUserId =
           currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore firestore;
  final String? Function() _currentUserId;

  Stream<Map<String, int>> watchInventory() {
    return firestore.collection('masterDealerInventory').snapshots().map((
      snapshot,
    ) {
      final result = <String, int>{'lira': 0, 'para': 0};
      for (final document in snapshot.docs) {
        final quantity = _intValue(document.data()['quantity']);
        final reserved = _intValue(document.data()['reserved']);
        result[document.id] = quantity - reserved;
      }
      return result;
    });
  }

  Stream<InvestmentPortfolio> watchPortfolio() {
    final uid = _currentUserId();
    if (uid == null) {
      return Stream.value(const InvestmentPortfolio());
    }

    return firestore
        .collection('masterDealerTransactions')
        .where('customerUid', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          var lira = 0;
          var para = 0;
          for (final document in snapshot.docs) {
            final data = document.data();
            final type = data['type'];
            if (type != 'customer_purchase' && type != 'customer_buyback') {
              continue;
            }
            final direction = type == 'customer_purchase' ? 1 : -1;
            lira += direction * _intValue(data['liraQuantity']);
            para += direction * _intValue(data['paraQuantity']);
          }
          return InvestmentPortfolio(
            liraQuantity: lira < 0 ? 0 : lira,
            paraQuantity: para < 0 ? 0 : para,
          );
        });
  }

  Stream<List<InvestmentActivity>> watchActivity() {
    final uid = _currentUserId();
    if (uid == null) return Stream.value(const []);

    return firestore
        .collection('masterDealerTransactions')
        .where('customerUid', isEqualTo: uid)
        .where('status', isEqualTo: 'completed')
        .snapshots()
        .map((snapshot) {
          final entries = snapshot.docs
              .where((document) {
                final type = document.data()['type'];
                return type == 'customer_purchase' ||
                    type == 'customer_buyback';
              })
              .map((document) {
                final data = document.data();
                final created = data['createdAt'];
                DateTime? date;
                if (created is Timestamp) date = created.toDate();
                if (created is String) date = DateTime.tryParse(created);
                final type = data['type'] == 'customer_buyback'
                    ? 'Buyback'
                    : 'Purchase';
                final lira = _intValue(data['liraQuantity']);
                final para = _intValue(data['paraQuantity']);
                final isLira = lira > 0;
                return InvestmentActivity(
                  unit: isLira ? 'LIRA' : 'PARA',
                  type: type,
                  date: date,
                  quantity: isLira ? lira : para,
                  status: 'Completed',
                );
              })
              .toList();
          entries.sort(
            (left, right) =>
                (right.date ?? DateTime.fromMillisecondsSinceEpoch(0))
                    .compareTo(
                      left.date ?? DateTime.fromMillisecondsSinceEpoch(0),
                    ),
          );
          return entries.take(10).toList();
        });
  }

  Stream<List<double>> watchPriceHistory() {
    return firestore
        .collection('masterDealerPriceHistory')
        .orderBy('createdAt', descending: true)
        .limit(24)
        .snapshots()
        .map((snapshot) {
          final values = snapshot.docs
              .map(
                (document) =>
                    _doubleValue(document.data()['combinedLiquidationMinor']) /
                    100,
              )
              .where((value) => value > 0)
              .toList()
              .reversed
              .toList();
          return values;
        });
  }

  Future<String> createPendingPurchase({
    required String unit,
    required int quantity,
    required int unitPriceMinor,
  }) async {
    final uid = _requireUser();
    if (!const ['lira', 'para'].contains(unit) ||
        quantity <= 0 ||
        quantity > 10000 ||
        unitPriceMinor <= 0) {
      throw ArgumentError('Invalid investment purchase.');
    }

    final orderRef = firestore.collection('masterDealerPurchaseOrders').doc();
    final inventoryRef = firestore
        .collection('masterDealerInventory')
        .doc(unit);
    final amountMinor = unitPriceMinor * quantity;
    await firestore.runTransaction((transaction) async {
      final inventoryDocument = await transaction.get(inventoryRef);
      if (!inventoryDocument.exists) {
        throw StateError('Inventory for ${unit.toUpperCase()} is unavailable.');
      }
      final inventory = inventoryDocument.data() ?? const <String, dynamic>{};
      final available =
          _intValue(inventory['quantity']) - _intValue(inventory['reserved']);
      if (quantity > available) {
        throw StateError('There is not enough ${unit.toUpperCase()} in stock.');
      }
      final now = DateTime.now();
      transaction.set(orderRef, {
        'customerUid': uid,
        'liraQuantity': unit == 'lira' ? quantity : 0,
        'paraQuantity': unit == 'para' ? quantity : 0,
        'liraUnitPriceMinor': unit == 'lira' ? unitPriceMinor : 0,
        'paraUnitPriceMinor': unit == 'para' ? unitPriceMinor : 0,
        'amountMinorUnits': amountMinor,
        'currency': 'EGP',
        'status': 'pending',
        'createdAt': now.toIso8601String(),
        'expiresAt': now.add(const Duration(minutes: 15)).toIso8601String(),
        'merchantOrderId': 'khan-md-${orderRef.id}',
      });
      transaction.update(inventoryRef, {
        'reserved': _intValue(inventory['reserved']) + quantity,
        'updatedAt': now.toIso8601String(),
      });
    });
    return orderRef.id;
  }

  Future<void> attachPaymobOrder({
    required String orderId,
    required String paymobOrderId,
  }) async {
    final uid = _requireUser();
    final orderRef = firestore
        .collection('masterDealerPurchaseOrders')
        .doc(orderId);
    await firestore.runTransaction((transaction) async {
      final order = await transaction.get(orderRef);
      if (!order.exists || order.data()?['customerUid'] != uid) {
        throw StateError('Purchase order not found.');
      }
      if (order.data()?['status'] != 'pending') {
        throw StateError('Purchase order is no longer pending.');
      }
      transaction.update(orderRef, {'paymobOrderId': paymobOrderId});
    });
  }

  Future<bool> completePurchase({
    required String orderId,
    required VerifiedPaymobPayment payment,
  }) async {
    final uid = _requireUser();
    final orderRef = firestore
        .collection('masterDealerPurchaseOrders')
        .doc(orderId);
    final paymentRef = firestore
        .collection('masterDealerTransactions')
        .doc('payment-${payment.transactionId}');

    return firestore.runTransaction((transaction) async {
      final orderDocument = await transaction.get(orderRef);
      final paymentDocument = await transaction.get(paymentRef);
      if (!orderDocument.exists ||
          orderDocument.data()?['customerUid'] != uid) {
        throw StateError('Purchase order not found.');
      }
      final order = orderDocument.data()!;
      if (paymentDocument.exists) {
        final existing = paymentDocument.data()!;
        if (existing['customerUid'] == uid &&
            existing['purchaseOrderId'] == orderId) {
          return false;
        }
        throw StateError('This Paymob transaction was already used.');
      }
      if (order['status'] == 'completed' &&
          order['paymentTransactionId'] == payment.transactionId) {
        return false;
      }
      if (order['status'] != 'pending') {
        throw StateError('Purchase order is no longer pending.');
      }

      final expectedMerchantOrderId = order['merchantOrderId']?.toString();
      final amountMinor = _intValue(order['amountMinorUnits']);
      if (payment.merchantOrderId != expectedMerchantOrderId ||
          payment.amountMinor != amountMinor ||
          order['currency'] != 'EGP') {
        throw StateError('Verified Paymob payment does not match this order.');
      }
      if (DateTime.tryParse(order['expiresAt']?.toString() ?? '')
              ?.isBefore(DateTime.now()) ??
          true) {
        throw StateError('Purchase order has expired.');
      }

      final liraQuantity = _intValue(order['liraQuantity']);
      final paraQuantity = _intValue(order['paraQuantity']);
      final unit = liraQuantity > 0 ? 'lira' : 'para';
      final quantity = liraQuantity + paraQuantity;
      final inventoryRef = firestore
          .collection('masterDealerInventory')
          .doc(unit);
      final portfolioRef = firestore.collection('customerPortfolios').doc(uid);
      final inventoryDocument = await transaction.get(inventoryRef);
      final portfolioDocument = await transaction.get(portfolioRef);
      if (!inventoryDocument.exists) {
        throw StateError('Inventory for ${unit.toUpperCase()} is unavailable.');
      }
      final inventory = inventoryDocument.data()!;
      final portfolio = portfolioDocument.data() ?? const <String, dynamic>{};
      final reserved = _intValue(inventory['reserved']);
      final stock = _intValue(inventory['quantity']);
      if (reserved < quantity || stock < quantity) {
        throw StateError('Reserved inventory no longer matches this order.');
      }

      final now = DateTime.now().toIso8601String();
      transaction.update(inventoryRef, {
        'quantity': stock - quantity,
        'reserved': reserved - quantity,
        'updatedAt': now,
      });
      transaction.update(orderRef, {
        'status': 'completed',
        'paymentTransactionId': payment.transactionId,
        'paidAt': now,
      });
      transaction.set(paymentRef, {
        'type': 'customer_purchase',
        'status': 'completed',
        'source': 'paymob',
        'customerUid': uid,
        'purchaseOrderId': orderId,
        'paymentTransactionId': payment.transactionId,
        'liraQuantity': liraQuantity,
        'paraQuantity': paraQuantity,
        'liraUnitPriceMinor': _intValue(order['liraUnitPriceMinor']),
        'paraUnitPriceMinor': _intValue(order['paraUnitPriceMinor']),
        'amountMinorUnits': amountMinor,
        'createdAt': now,
      });
      transaction.set(portfolioRef, {
        'liraQuantity': _intValue(portfolio['liraQuantity']) + liraQuantity,
        'paraQuantity': _intValue(portfolio['paraQuantity']) + paraQuantity,
        'updatedAt': now,
      }, SetOptions(merge: true));
      return true;
    });
  }

  Future<void> cancelPurchase(String orderId) async {
    final uid = _requireUser();
    final orderRef = firestore
        .collection('masterDealerPurchaseOrders')
        .doc(orderId);
    await firestore.runTransaction((transaction) async {
      final orderDocument = await transaction.get(orderRef);
      if (!orderDocument.exists ||
          orderDocument.data()?['customerUid'] != uid) {
        throw StateError('Purchase order not found.');
      }
      final order = orderDocument.data()!;
      if (order['status'] != 'pending') return;

      final liraQuantity = _intValue(order['liraQuantity']);
      final paraQuantity = _intValue(order['paraQuantity']);
      final unit = liraQuantity > 0 ? 'lira' : 'para';
      final quantity = liraQuantity + paraQuantity;
      final inventoryRef = firestore
          .collection('masterDealerInventory')
          .doc(unit);
      final inventoryDocument = await transaction.get(inventoryRef);
      if (!inventoryDocument.exists) {
        throw StateError('Inventory for ${unit.toUpperCase()} is unavailable.');
      }
      final inventory = inventoryDocument.data()!;
      final reserved = _intValue(inventory['reserved']);
      if (reserved < quantity) {
        throw StateError('Reserved inventory no longer matches this order.');
      }
      transaction.update(inventoryRef, {
        'reserved': reserved - quantity,
        'updatedAt': DateTime.now().toIso8601String(),
      });
      transaction.update(orderRef, {
        'status': 'cancelled',
        'cancelledAt': DateTime.now().toIso8601String(),
      });
    });
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null || uid.isEmpty) {
      throw StateError('Sign in before purchasing an investment.');
    }
    return uid;
  }

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double _doubleValue(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
