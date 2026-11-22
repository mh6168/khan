import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/jeweler_profile.dart';
import '../models/jewelry_product.dart';
import '../models/jewelry_reservation.dart';
import 'paymob_service.dart';

class ReservationQuote {
  const ReservationQuote({
    required this.productId,
    required this.productName,
    required this.jewelerId,
    required this.jewelerStoreName,
    required this.totalMinor,
    required this.depositMinor,
    required this.remainingMinor,
  });

  factory ReservationQuote.fromProduct(
    JewelryProduct product,
    JewelerProfile? jeweler,
  ) {
    final priceEgp = product.priceEgp;
    if (priceEgp == null || !priceEgp.isFinite || priceEgp <= 0) {
      throw StateError('The current product price is unavailable.');
    }
    final totalMinor = (priceEgp * 100).round();
    final depositMinor = (totalMinor / 10).round();
    final jewelerId = product.jewelerId ?? jeweler?.id ?? '';
    if (jewelerId.isEmpty || totalMinor <= 0 || depositMinor <= 0) {
      throw StateError('The reservation details are unavailable.');
    }
    return ReservationQuote(
      productId: product.id,
      productName: product.name,
      jewelerId: jewelerId,
      jewelerStoreName: jeweler?.displayName ?? 'KHAN jeweler',
      totalMinor: totalMinor,
      depositMinor: depositMinor,
      remainingMinor: totalMinor - depositMinor,
    );
  }

  final String productId;
  final String productName;
  final String jewelerId;
  final String jewelerStoreName;
  final int totalMinor;
  final int depositMinor;
  final int remainingMinor;
}

class ReservationCheckout {
  const ReservationCheckout({
    required this.orderId,
    required this.customerUid,
    required this.productId,
    required this.productName,
    required this.jewelerId,
    required this.jewelerStoreName,
    required this.totalMinor,
    required this.depositMinor,
    required this.remainingMinor,
    required this.merchantOrderId,
    required this.status,
    this.paymobOrderId,
  });

  factory ReservationCheckout.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return ReservationCheckout(
      orderId: id,
      customerUid: data['customerUid']?.toString() ?? '',
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? 'Jewelry piece',
      jewelerId: data['jewelerId']?.toString() ?? '',
      jewelerStoreName: data['jewelerStoreName']?.toString() ?? 'KHAN jeweler',
      totalMinor: _int(data['totalPriceMinorUnits']),
      depositMinor: _int(data['depositAmountMinorUnits']),
      remainingMinor: _int(data['remainingBalanceMinorUnits']),
      merchantOrderId: data['merchantOrderId']?.toString() ?? '',
      status: data['status']?.toString() ?? '',
      paymobOrderId: data['paymobOrderId']?.toString(),
    );
  }

  final String orderId;
  final String customerUid;
  final String productId;
  final String productName;
  final String jewelerId;
  final String jewelerStoreName;
  final int totalMinor;
  final int depositMinor;
  final int remainingMinor;
  final String merchantOrderId;
  final String status;
  final String? paymobOrderId;

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReservationService {
  ReservationService({
    FirebaseFirestore? firestore,
    String? Function()? currentUserId,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _currentUserId =
           currentUserId ?? (() => FirebaseAuth.instance.currentUser?.uid);

  final FirebaseFirestore _firestore;
  final String? Function() _currentUserId;

  Future<ReservationCheckout> createCheckout({
    required JewelryProduct product,
    required ReservationQuote quote,
    String? customerName,
    String? customerEmail,
    String? customerPhone,
  }) async {
    final uid = _requireUser();
    final profileSnapshot = await _firestore.collection('users').doc(uid).get();
    final profile = profileSnapshot.data() ?? const <String, dynamic>{};
    final productRef = _firestore.collection('products').doc(product.id);
    final orderRef = _firestore.collection('jewelryReservationOrders').doc();
    final merchantOrderId = 'khan-rsv-${orderRef.id}';
    final now = DateTime.now();
    final lockExpiresAt = now.add(const Duration(minutes: 15));

    await _firestore.runTransaction((transaction) async {
      final productSnapshot = await transaction.get(productRef);
      if (!productSnapshot.exists) {
        throw StateError('This product is no longer available.');
      }
      final productData = productSnapshot.data() ?? const <String, dynamic>{};
      DocumentReference<Map<String, dynamic>>? staleOrderRef;
      DocumentSnapshot<Map<String, dynamic>>? staleOrderSnapshot;

      if (productData['availability'] == 'reserved_pending') {
        final lockExpires = _date(productData['reservationLockExpiresAt']);
        if (lockExpires != null && lockExpires.isAfter(now)) {
          throw StateError('This product is currently reserved for checkout.');
        }
        final staleOrderId = productData['reservationLockOrderId']?.toString();
        if (staleOrderId != null && staleOrderId.isNotEmpty) {
          staleOrderRef = _firestore
              .collection('jewelryReservationOrders')
              .doc(staleOrderId);
          staleOrderSnapshot = await transaction.get(staleOrderRef);
        }
      } else if (productData['availability'] != 'available') {
        throw StateError('This product is no longer available.');
      }

      if ((productData['activeReservationId']?.toString() ?? '').isNotEmpty) {
        throw StateError('This product already has an active reservation.');
      }

      if (staleOrderRef != null &&
          staleOrderSnapshot?.exists == true &&
          staleOrderSnapshot?.data()?['status'] == 'pending') {
        transaction.update(staleOrderRef, {
          'status': 'expired',
          'expiredAt': FieldValue.serverTimestamp(),
        });
      }

      final photoPaths = productData['photoPaths'];
      final productImagePath = photoPaths is List && photoPaths.isNotEmpty
          ? photoPaths.first?.toString() ?? ''
          : '';
      transaction.set(orderRef, {
        'orderId': orderRef.id,
        'customerUid': uid,
        'customerName':
            profile['name']?.toString() ?? customerName ?? 'KHAN customer',
        'customerEmail': profile['email']?.toString() ?? customerEmail ?? '',
        'customerPhone': profile['phone']?.toString() ?? customerPhone ?? '',
        'productId': quote.productId,
        'productName': quote.productName,
        'productImagePath': productImagePath,
        'jewelerId': quote.jewelerId,
        'jewelerStoreName': quote.jewelerStoreName,
        'totalPriceMinorUnits': quote.totalMinor,
        'depositAmountMinorUnits': quote.depositMinor,
        'remainingBalanceMinorUnits': quote.remainingMinor,
        'currency': 'EGP',
        'paymentGateway': 'paymob',
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(lockExpiresAt),
        'merchantOrderId': merchantOrderId,
      });
      transaction.update(productRef, {
        'availability': 'reserved_pending',
        'reservationLockOrderId': orderRef.id,
        'reservationLockExpiresAt': Timestamp.fromDate(lockExpiresAt),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return ReservationCheckout(
      orderId: orderRef.id,
      customerUid: uid,
      productId: quote.productId,
      productName: quote.productName,
      jewelerId: quote.jewelerId,
      jewelerStoreName: quote.jewelerStoreName,
      totalMinor: quote.totalMinor,
      depositMinor: quote.depositMinor,
      remainingMinor: quote.remainingMinor,
      merchantOrderId: merchantOrderId,
      status: 'pending',
    );
  }

  Future<void> attachPaymobOrder({
    required String orderId,
    required String paymobOrderId,
  }) async {
    final uid = _requireUser();
    final orderRef = _firestore
        .collection('jewelryReservationOrders')
        .doc(orderId);
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final data = orderSnapshot.data();
      if (data == null || data['customerUid'] != uid) {
        throw StateError('Reservation checkout not found.');
      }
      if (data['status'] != 'pending') {
        throw StateError('Reservation checkout is no longer pending.');
      }
      transaction.update(orderRef, {'paymobOrderId': paymobOrderId});
    });
  }

  Future<ReservationCheckout> getCheckout(String orderId) async {
    final uid = _requireUser();
    final snapshot = await _firestore
        .collection('jewelryReservationOrders')
        .doc(orderId)
        .get();
    final data = snapshot.data();
    if (data == null || data['customerUid'] != uid) {
      throw StateError('Reservation checkout not found.');
    }
    return ReservationCheckout.fromFirestore(snapshot.id, data);
  }

  Future<bool> completePayment({
    required String orderId,
    required VerifiedPaymobPayment payment,
  }) async {
    final uid = _requireUser();
    final orderRef = _firestore
        .collection('jewelryReservationOrders')
        .doc(orderId);
    final reservationRef = _firestore
        .collection('jewelryReservations')
        .doc(orderId);
    final paymentRef = _firestore
        .collection('jewelryReservationPayments')
        .doc('payment-${payment.transactionId}');

    return _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final paymentSnapshot = await transaction.get(paymentRef);
      final reservationSnapshot = await transaction.get(reservationRef);
      final order = orderSnapshot.data();
      if (order == null || order['customerUid'] != uid) {
        throw StateError('Reservation checkout not found.');
      }
      if (order['status'] == 'completed' &&
          order['paymobTransactionId'] == payment.transactionId) {
        return false;
      }
      if (order['status'] != 'pending') {
        throw StateError('Reservation checkout is no longer pending.');
      }
      if (paymentSnapshot.exists) {
        final existing = paymentSnapshot.data() ?? const <String, dynamic>{};
        if (existing['customerUid'] == uid &&
            existing['reservationOrderId'] == orderId) {
          return false;
        }
        throw StateError('This Paymob transaction was already used.');
      }
      if (reservationSnapshot.exists) {
        throw StateError('This reservation has already been created.');
      }
      if (payment.merchantOrderId != order['merchantOrderId'] ||
          payment.amountMinor !=
              ReservationCheckout._int(order['depositAmountMinorUnits']) ||
          order['currency'] != 'EGP') {
        throw StateError('Verified Paymob payment does not match this order.');
      }
      final orderExpiry = _date(order['expiresAt']);
      if (orderExpiry == null || orderExpiry.isBefore(DateTime.now())) {
        throw StateError('Reservation checkout has expired.');
      }

      final productRef = _firestore
          .collection('products')
          .doc(order['productId'].toString());
      final productSnapshot = await transaction.get(productRef);
      final productData = productSnapshot.data();
      if (productData == null ||
          productData['availability'] != 'reserved_pending' ||
          productData['reservationLockOrderId'] != orderId) {
        throw StateError('Product is no longer reserved for this checkout.');
      }

      final now = DateTime.now();
      final expiresAt = Timestamp.fromDate(now.add(const Duration(hours: 48)));
      final totalMinor = ReservationCheckout._int(
        order['totalPriceMinorUnits'],
      );
      final depositMinor = ReservationCheckout._int(
        order['depositAmountMinorUnits'],
      );
      final remainingMinor = ReservationCheckout._int(
        order['remainingBalanceMinorUnits'],
      );

      transaction.set(reservationRef, {
        'reservationId': orderId,
        'customerUid': uid,
        'customerName': order['customerName'] ?? '',
        'customerEmail': order['customerEmail'] ?? '',
        'customerPhone': order['customerPhone'] ?? '',
        'productId': order['productId'],
        'productName': order['productName'],
        'productImagePath': order['productImagePath'] ?? '',
        'jewelerId': order['jewelerId'],
        'jewelerStoreName': order['jewelerStoreName'],
        'originalTotalPriceMinorUnits': totalMinor,
        'originalTotalPriceEgp': totalMinor / 100,
        'depositAmountMinorUnits': depositMinor,
        'depositAmountEgp': depositMinor / 100,
        'remainingBalanceMinorUnits': remainingMinor,
        'remainingBalanceEgp': remainingMinor / 100,
        'paymentGateway': 'paymob',
        'paymobTransactionId': payment.transactionId,
        'paymobOrderId': order['paymobOrderId'] ?? '',
        'reservationCreatedAt': FieldValue.serverTimestamp(),
        'reservationExpiresAt': expiresAt,
        'status': 'reserved_for_48_hours',
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
      });
      transaction.update(orderRef, {
        'status': 'completed',
        'reservationId': orderId,
        'paymobTransactionId': payment.transactionId,
        'paymentTransactionId': payment.transactionId,
        'paidAt': FieldValue.serverTimestamp(),
        'completedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(paymentRef, {
        'reservationOrderId': orderId,
        'reservationId': orderId,
        'customerUid': uid,
        'paymobTransactionId': payment.transactionId,
        'paymobOrderId': order['paymobOrderId'] ?? '',
        'amountMinorUnits': payment.amountMinor,
        'currency': 'EGP',
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(productRef, {
        'availability': 'unavailable',
        'activeReservationId': orderId,
        'reservedAt': FieldValue.serverTimestamp(),
        'reservedUntil': expiresAt,
        'reservationStatus': 'reserved_for_48_hours',
        'reservationLockOrderId': FieldValue.delete(),
        'reservationLockExpiresAt': FieldValue.delete(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return true;
    });
  }

  Future<void> cancelCheckout(String orderId) async {
    final uid = _requireUser();
    final orderRef = _firestore
        .collection('jewelryReservationOrders')
        .doc(orderId);
    await _firestore.runTransaction((transaction) async {
      final orderSnapshot = await transaction.get(orderRef);
      final order = orderSnapshot.data();
      if (order == null || order['customerUid'] != uid) {
        throw StateError('Reservation checkout not found.');
      }
      if (order['status'] != 'pending') return;

      final productRef = _firestore
          .collection('products')
          .doc(order['productId'].toString());
      final productSnapshot = await transaction.get(productRef);
      final product = productSnapshot.data();
      transaction.update(orderRef, {
        'status': 'cancelled',
        'cancelledAt': FieldValue.serverTimestamp(),
      });
      if (product != null && product['reservationLockOrderId'] == orderId) {
        transaction.update(productRef, {
          'availability': 'available',
          'reservationLockOrderId': FieldValue.delete(),
          'reservationLockExpiresAt': FieldValue.delete(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Stream<List<JewelryReservation>> watchMyReservations(String uid) {
    final query = _firestore
        .collection('jewelryReservations')
        .where('customerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true);
    return query.snapshots().asyncMap((snapshot) async {
      final expired = snapshot.docs
          .where((document) {
            final data = document.data();
            final expiresAt = _date(
              data['reservationExpiresAt'] ?? data['expiresAt'],
            );
            return data['status'] == 'reserved_for_48_hours' &&
                expiresAt != null &&
                !expiresAt.isAfter(DateTime.now());
          })
          .toList(growable: false);
      if (expired.isNotEmpty) {
        await Future.wait(
          expired.map(
            (document) =>
                document.reference.update({'status': 'user_didnt_pick_up'}),
          ),
        );
        final refreshed = await query.get();
        return refreshed.docs
            .map(
              (document) => JewelryReservation.fromFirestore(
                document.id,
                document.data(),
              ),
            )
            .toList(growable: false);
      }
      return snapshot.docs
          .map(
            (document) =>
                JewelryReservation.fromFirestore(document.id, document.data()),
          )
          .toList(growable: false);
    });
  }

  String _requireUser() {
    final uid = _currentUserId();
    if (uid == null || uid.isEmpty) throw StateError('Sign in required.');
    return uid;
  }

  static DateTime? _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }
}
