import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:http/http.dart' as http;

import '../models/jewelry_reservation.dart';

class ReservationQuote {
  const ReservationQuote({
    required this.productId,
    required this.productName,
    required this.productImagePath,
    required this.jewelerId,
    required this.jewelerStoreName,
    required this.totalMinor,
    required this.depositMinor,
    required this.remainingMinor,
  });

  factory ReservationQuote.fromMap(Map<String, dynamic> data) {
    return ReservationQuote(
      productId: data['productId']?.toString() ?? '',
      productName: data['productName']?.toString() ?? 'Jewelry piece',
      productImagePath: data['productImagePath']?.toString() ?? '',
      jewelerId: data['jewelerId']?.toString() ?? '',
      jewelerStoreName: data['jewelerStoreName']?.toString() ?? 'KHAN jeweler',
      totalMinor: _int(data['totalMinor']),
      depositMinor: _int(data['depositMinor']),
      remainingMinor: _int(data['remainingMinor']),
    );
  }

  final String productId;
  final String productName;
  final String productImagePath;
  final String jewelerId;
  final String jewelerStoreName;
  final int totalMinor;
  final int depositMinor;
  final int remainingMinor;

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class ReservationCheckout {
  const ReservationCheckout({
    required this.orderId,
    required this.paymobOrderId,
    required this.merchantOrderId,
    required this.amountMinor,
    required this.checkoutUrl,
  });

  factory ReservationCheckout.fromMap(Map<String, dynamic> data) {
    return ReservationCheckout(
      orderId: data['orderId']?.toString() ?? '',
      paymobOrderId: data['paymobOrderId']?.toString() ?? '',
      merchantOrderId: data['merchantOrderId']?.toString() ?? '',
      amountMinor: ReservationQuote._int(data['amountMinor']),
      checkoutUrl: Uri.parse(data['checkoutUrl']?.toString() ?? ''),
    );
  }

  final String orderId;
  final String paymobOrderId;
  final String merchantOrderId;
  final int amountMinor;
  final Uri checkoutUrl;
}

class ReservationService {
  ReservationService({FirebaseFirestore? firestore, http.Client? client})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _client = client,
      _ownsClient = client == null;

  final FirebaseFirestore _firestore;
  final http.Client? _client;
  final bool _ownsClient;

  Future<ReservationQuote> getQuote(String productId) async {
    final result = await _call('getJewelryReservationQuote', {
      'productId': productId,
    });
    return ReservationQuote.fromMap(result);
  }

  Future<ReservationCheckout> createCheckout({
    required String productId,
    String? returnUrl,
  }) async {
    final result = await _call('createJewelryReservationCheckout', {
      'productId': productId,
      if (returnUrl != null && returnUrl.isNotEmpty) 'returnUrl': returnUrl,
    });
    return ReservationCheckout.fromMap(result);
  }

  Future<Map<String, dynamic>> confirmPayment({
    required String orderId,
    required String transactionId,
  }) async {
    return _call('confirmJewelryReservationPayment', {
      'orderId': orderId,
      'paymobTransactionId': transactionId,
    });
  }

  Future<void> cancelCheckout(String orderId) async {
    await _call('cancelJewelryReservationCheckout', {'orderId': orderId});
  }

  Stream<List<JewelryReservation>> watchMyReservations(String uid) {
    return _firestore
        .collection('jewelryReservations')
        .where('customerUid', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (document) => JewelryReservation.fromFirestore(
                  document.id,
                  document.data(),
                ),
              )
              .toList(growable: false),
        );
  }

  Future<Map<String, dynamic>> _call(
    String functionName,
    Map<String, dynamic> data,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Sign in required.');
    final token = await user.getIdToken();
    final projectId = Firebase.app().options.projectId;
    final uri = Uri.parse(
      'https://us-central1-$projectId.cloudfunctions.net/$functionName',
    );
    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'data': data}),
          )
          .timeout(const Duration(seconds: 30));
      dynamic payload;
      try {
        payload = jsonDecode(response.body);
      } on FormatException {
        throw Exception('The payment service returned an invalid response.');
      }
      if (response.statusCode < 200 || response.statusCode >= 300) {
        String? message;
        if (payload is Map && payload['error'] is Map) {
          message = (payload['error'] as Map)['message']?.toString();
        }
        throw Exception(
          message == null || message.isEmpty
              ? 'The payment service is unavailable.'
              : message,
        );
      }
      if (payload is Map && payload['error'] is Map) {
        final message = (payload['error'] as Map)['message']?.toString();
        throw Exception(
          message == null || message.isEmpty
              ? 'The payment service rejected the request.'
              : message,
        );
      }
      if (payload is Map && payload['result'] is Map) {
        return Map<String, dynamic>.from(payload['result'] as Map);
      }
      if (payload is Map && payload['data'] is Map) {
        return Map<String, dynamic>.from(payload['data'] as Map);
      }
      throw Exception('The payment service returned an unexpected response.');
    } finally {
      if (_ownsClient) client.close();
    }
  }
}
