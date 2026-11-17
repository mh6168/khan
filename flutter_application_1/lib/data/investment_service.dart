import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/investment.dart';

class InvestmentService {
  InvestmentService({FirebaseFirestore? firestore, FirebaseFunctions? functions})
      : firestore = firestore ?? FirebaseFirestore.instance,
        functions = functions ??
            FirebaseFunctions.instanceFor(region: 'us-central1');

  final FirebaseFirestore firestore;
  final FirebaseFunctions functions;

  Stream<Map<String, dynamic>> watchPrices() {
    return firestore
        .collection('masterDealerPrices')
        .doc('current')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? const {});
  }

  Stream<Map<String, int>> watchInventory() {
    return firestore
        .collection('masterDealerInventory')
        .snapshots()
        .map((snapshot) {
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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
      entries.sort((left, right) =>
          (right.date ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(left.date ?? DateTime.fromMillisecondsSinceEpoch(0)));
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
          .map((document) =>
              _doubleValue(document.data()['combinedLiquidationMinor']) / 100)
          .where((value) => value > 0)
          .toList()
          .reversed
          .toList();
      return values;
    });
  }

  Future<Map<String, dynamic>> createPurchase({
    required String unit,
    required int quantity,
  }) async {
    final result = await functions.httpsCallable('createInvestmentPurchase').call({
      'unit': unit,
      'quantity': quantity,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<Map<String, dynamic>> confirmPurchase({
    required String orderId,
    required String paymobTransactionId,
  }) async {
    final result =
        await functions.httpsCallable('confirmInvestmentPurchase').call({
      'orderId': orderId,
      'paymobTransactionId': paymobTransactionId,
    });
    return Map<String, dynamic>.from(result.data as Map);
  }

  Future<void> refreshPrices() async {
    await functions.httpsCallable('updateInvestmentPrices').call();
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
