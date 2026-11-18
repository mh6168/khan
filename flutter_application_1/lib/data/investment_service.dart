import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'paymob_service.dart';
import '../models/investment.dart';
import '../models/investment_sell_request.dart';

class InvestmentPurchaseOrder {
  const InvestmentPurchaseOrder({
    required this.id,
    required this.unit,
    required this.quantity,
    required this.amountMinor,
    required this.currency,
    required this.merchantOrderId,
    required this.status,
    this.paymentTransactionId,
  });

  final String id;
  final String unit;
  final int quantity;
  final int amountMinor;
  final String currency;
  final String merchantOrderId;
  final String status;
  final String? paymentTransactionId;
}

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

    return firestore.collection('customerPortfolios').doc(uid).snapshots().map((
      snapshot,
    ) {
      final data = snapshot.data() ?? const <String, dynamic>{};
      final lira =
          _intValue(data['liraQuantity']) -
          _intValue(data['reservedLiraQuantity']);
      final para =
          _intValue(data['paraQuantity']) -
          _intValue(data['reservedParaQuantity']);
      return InvestmentPortfolio(
        liraQuantity: lira < 0 ? 0 : lira,
        paraQuantity: para < 0 ? 0 : para,
      );
    });
  }

  Stream<List<InvestmentSellRequest>> watchCustomerSellRequests() {
    final uid = _currentUserId();
    if (uid == null) return Stream.value(const []);
    return firestore
        .collection('masterDealerSellRequests')
        .where('customerUid', isEqualTo: uid)
        .snapshots()
        .map(_sortedSellRequests);
  }

  Stream<List<InvestmentSellRequest>> watchMasterDealerSellRequests() {
    _requireUser();
    return firestore
        .collection('masterDealerSellRequests')
        .snapshots()
        .map(_sortedSellRequests);
  }

  Future<String> createSellRequest({
    required int liraQuantity,
    required int paraQuantity,
    required String instapayPhone,
    required int liraUnitPriceMinor,
    required int paraUnitPriceMinor,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
  }) async {
    final uid = _requireUser();
    final normalizedPhone = normalizeEgyptianMobile(instapayPhone);
    if (normalizedPhone == null) {
      throw ArgumentError('Enter a valid Egyptian mobile number.');
    }
    if (liraQuantity < 0 ||
        paraQuantity < 0 ||
        liraQuantity > 10000 ||
        paraQuantity > 10000 ||
        (liraQuantity == 0 && paraQuantity == 0)) {
      throw ArgumentError('Enter a positive quantity for at least one asset.');
    }
    if (liraUnitPriceMinor <= 0 || paraUnitPriceMinor <= 0) {
      throw ArgumentError('Current sellback prices are unavailable.');
    }

    final requestRef = firestore.collection('masterDealerSellRequests').doc();
    final portfolioRef = firestore.collection('customerPortfolios').doc(uid);
    final totalPayoutMinor =
        liraQuantity * liraUnitPriceMinor + paraQuantity * paraUnitPriceMinor;

    await firestore.runTransaction((transaction) async {
      final portfolioDocument = await transaction.get(portfolioRef);
      if (!portfolioDocument.exists) {
        throw StateError('No investment holdings are available to sell.');
      }
      final portfolio = portfolioDocument.data()!;
      final liraAvailable =
          _intValue(portfolio['liraQuantity']) -
          _intValue(portfolio['reservedLiraQuantity']);
      final paraAvailable =
          _intValue(portfolio['paraQuantity']) -
          _intValue(portfolio['reservedParaQuantity']);
      if (liraQuantity > liraAvailable || paraQuantity > paraAvailable) {
        throw StateError(
          'The requested quantity exceeds your available holdings.',
        );
      }

      transaction.set(requestRef, {
        'customerUid': uid,
        'customerName': customerName.trim(),
        'customerEmail': customerEmail.trim(),
        'customerPhone': customerPhone.trim(),
        'instapayPhone': normalizedPhone,
        'liraQuantity': liraQuantity,
        'paraQuantity': paraQuantity,
        'liraUnitPriceMinor': liraUnitPriceMinor,
        'paraUnitPriceMinor': paraUnitPriceMinor,
        'totalPayoutMinor': totalPayoutMinor,
        'currency': 'EGP',
        'status': 'processing',
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(portfolioRef, {
        'reservedLiraQuantity':
            _intValue(portfolio['reservedLiraQuantity']) + liraQuantity,
        'reservedParaQuantity':
            _intValue(portfolio['reservedParaQuantity']) + paraQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
    return requestRef.id;
  }

  Future<bool> markSellRequestMoneyTransferred(String requestId) async {
    final dealerUid = _requireUser();
    final requestRef = firestore
        .collection('masterDealerSellRequests')
        .doc(requestId);
    final transactionRef = firestore
        .collection('masterDealerTransactions')
        .doc('buyback-$requestId');

    return firestore.runTransaction((transaction) async {
      final requestDocument = await transaction.get(requestRef);
      if (!requestDocument.exists) {
        throw StateError('Buyback request not found.');
      }
      final request = requestDocument.data()!;
      if (request['status'] == 'money_transferred') return false;
      if (request['status'] != 'processing') {
        throw StateError('Buyback request is not awaiting transfer.');
      }

      final customerUid = request['customerUid']?.toString() ?? '';
      final liraQuantity = _intValue(request['liraQuantity']);
      final paraQuantity = _intValue(request['paraQuantity']);
      if (customerUid.isEmpty ||
          liraQuantity < 0 ||
          paraQuantity < 0 ||
          liraQuantity > 10000 ||
          paraQuantity > 10000 ||
          (liraQuantity == 0 && paraQuantity == 0)) {
        throw StateError('Buyback request data is invalid.');
      }
      final liraUnitPriceMinor = _intValue(request['liraUnitPriceMinor']);
      final paraUnitPriceMinor = _intValue(request['paraUnitPriceMinor']);
      final totalPayoutMinor = _intValue(request['totalPayoutMinor']);
      if (liraUnitPriceMinor <= 0 ||
          paraUnitPriceMinor <= 0 ||
          request['currency'] != 'EGP' ||
          totalPayoutMinor !=
              liraQuantity * liraUnitPriceMinor +
                  paraQuantity * paraUnitPriceMinor) {
        throw StateError('Buyback quote data is invalid.');
      }

      final portfolioRef = firestore
          .collection('customerPortfolios')
          .doc(customerUid);
      final liraInventoryRef = firestore
          .collection('masterDealerInventory')
          .doc('lira');
      final paraInventoryRef = firestore
          .collection('masterDealerInventory')
          .doc('para');
      final portfolioDocument = await transaction.get(portfolioRef);
      final liraInventoryDocument = await transaction.get(liraInventoryRef);
      final paraInventoryDocument = await transaction.get(paraInventoryRef);
      final transactionDocument = await transaction.get(transactionRef);

      if (!portfolioDocument.exists ||
          (liraQuantity > 0 && !liraInventoryDocument.exists) ||
          (paraQuantity > 0 && !paraInventoryDocument.exists)) {
        throw StateError(
          'Portfolio or Master Dealer inventory is unavailable.',
        );
      }
      if (transactionDocument.exists) {
        throw StateError('This buyback request was already recorded.');
      }

      final portfolio = portfolioDocument.data()!;
      final liraHeld = _intValue(portfolio['liraQuantity']);
      final paraHeld = _intValue(portfolio['paraQuantity']);
      final liraReserved = _intValue(portfolio['reservedLiraQuantity']);
      final paraReserved = _intValue(portfolio['reservedParaQuantity']);
      if (liraHeld < liraQuantity ||
          paraHeld < paraQuantity ||
          liraReserved < liraQuantity ||
          paraReserved < paraQuantity) {
        throw StateError(
          'Reserved customer holdings do not match this request.',
        );
      }

      final now = FieldValue.serverTimestamp();
      transaction.update(portfolioRef, {
        'liraQuantity': liraHeld - liraQuantity,
        'paraQuantity': paraHeld - paraQuantity,
        'reservedLiraQuantity': liraReserved - liraQuantity,
        'reservedParaQuantity': paraReserved - paraQuantity,
        'updatedAt': now,
      });
      if (liraQuantity > 0) {
        final inventory = liraInventoryDocument.data()!;
        transaction.update(liraInventoryRef, {
          'quantity': _intValue(inventory['quantity']) + liraQuantity,
          'updatedAt': now,
        });
      }
      if (paraQuantity > 0) {
        final inventory = paraInventoryDocument.data()!;
        transaction.update(paraInventoryRef, {
          'quantity': _intValue(inventory['quantity']) + paraQuantity,
          'updatedAt': now,
        });
      }
      transaction.update(requestRef, {
        'status': 'money_transferred',
        'transferredAt': now,
        'transferredBy': dealerUid,
      });
      transaction.set(transactionRef, {
        'type': 'customer_buyback',
        'status': 'completed',
        'source': 'instapay',
        'customerUid': customerUid,
        'buybackRequestId': requestId,
        'liraQuantity': liraQuantity,
        'paraQuantity': paraQuantity,
        'liraUnitPriceMinor': liraUnitPriceMinor,
        'paraUnitPriceMinor': paraUnitPriceMinor,
        'amountMinorUnits': totalPayoutMinor,
        'createdAt': now,
        'confirmedAt': now,
      });
      return true;
    });
  }

  static String? normalizeEgyptianMobile(String value) {
    final compact = value.trim().replaceAll(RegExp(r'[\s()-]'), '');
    if (!RegExp(r'^\+?\d+$').hasMatch(compact)) return null;
    var digits = compact.startsWith('+') ? compact.substring(1) : compact;
    if (digits.startsWith('0020')) {
      digits = '0${digits.substring(4)}';
    } else if (digits.startsWith('20') && digits.length == 12) {
      digits = '0${digits.substring(2)}';
    }
    if (RegExp(r'^01[0125]\d{8}$').hasMatch(digits)) return digits;
    return null;
  }

  List<InvestmentSellRequest> _sortedSellRequests(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final requests = snapshot.docs
        .map(InvestmentSellRequest.fromDocument)
        .toList();
    requests.sort(
      (left, right) =>
          (right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
            left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0),
          ),
    );
    return requests;
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
              .expand((document) {
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
                return [
                  if (lira > 0)
                    InvestmentActivity(
                      unit: 'LIRA',
                      type: type,
                      date: date,
                      quantity: lira,
                      status: 'Completed',
                    ),
                  if (para > 0)
                    InvestmentActivity(
                      unit: 'PARA',
                      type: type,
                      date: date,
                      quantity: para,
                      status: 'Completed',
                    ),
                ];
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

  Future<InvestmentPurchaseOrder> getPurchaseOrder(String orderId) async {
    final uid = _requireUser();
    final document = await firestore
        .collection('masterDealerPurchaseOrders')
        .doc(orderId)
        .get();
    final data = document.data();
    if (data == null || data['customerUid'] != uid) {
      throw StateError('Purchase order not found.');
    }

    final liraQuantity = _intValue(data['liraQuantity']);
    final paraQuantity = _intValue(data['paraQuantity']);
    if (liraQuantity < 0 ||
        paraQuantity < 0 ||
        (liraQuantity > 0) == (paraQuantity > 0)) {
      throw StateError('Purchase order asset data is invalid.');
    }
    final amountMinor = _intValue(data['amountMinorUnits']);
    final merchantOrderId = data['merchantOrderId']?.toString() ?? '';
    if (amountMinor <= 0 ||
        data['currency'] != 'EGP' ||
        merchantOrderId.isEmpty) {
      throw StateError('Purchase order payment data is invalid.');
    }
    return InvestmentPurchaseOrder(
      id: document.id,
      unit: liraQuantity > 0 ? 'lira' : 'para',
      quantity: liraQuantity + paraQuantity,
      amountMinor: amountMinor,
      currency: data['currency']?.toString() ?? '',
      merchantOrderId: merchantOrderId,
      status: data['status']?.toString() ?? '',
      paymentTransactionId: data['paymentTransactionId']?.toString(),
    );
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
