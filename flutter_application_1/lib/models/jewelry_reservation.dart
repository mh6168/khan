import 'package:cloud_firestore/cloud_firestore.dart';

class JewelryReservation {
  const JewelryReservation({
    required this.id,
    required this.customerUid,
    required this.productId,
    required this.productName,
    required this.jewelerId,
    required this.jewelerStoreName,
    required this.originalTotalPriceMinorUnits,
    required this.depositAmountMinorUnits,
    required this.remainingBalanceMinorUnits,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    this.customerName,
    this.customerEmail,
    this.customerPhone,
    this.productImagePath,
    this.paymobTransactionId,
    this.paymobOrderId,
  });

  factory JewelryReservation.fromFirestore(
    String id,
    Map<String, dynamic> data,
  ) {
    return JewelryReservation(
      id: id,
      customerUid: _string(data['customerUid']) ?? '',
      customerName: _string(data['customerName']),
      customerEmail: _string(data['customerEmail']),
      customerPhone: _string(data['customerPhone']),
      productId: _string(data['productId']) ?? '',
      productName: _string(data['productName']) ?? 'Jewelry piece',
      productImagePath: _string(data['productImagePath']),
      jewelerId: _string(data['jewelerId']) ?? '',
      jewelerStoreName: _string(data['jewelerStoreName']) ?? 'KHAN jeweler',
      originalTotalPriceMinorUnits: _int(data['originalTotalPriceMinorUnits']),
      depositAmountMinorUnits: _int(data['depositAmountMinorUnits']),
      remainingBalanceMinorUnits: _int(data['remainingBalanceMinorUnits']),
      paymobTransactionId: _string(data['paymobTransactionId']),
      paymobOrderId: _string(data['paymobOrderId']),
      status: _string(data['status']) ?? 'reserved_for_48_hours',
      createdAt: _date(data['reservationCreatedAt'] ?? data['createdAt']),
      expiresAt: _date(data['reservationExpiresAt'] ?? data['expiresAt']),
    );
  }

  final String id;
  final String customerUid;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final String productId;
  final String productName;
  final String? productImagePath;
  final String jewelerId;
  final String jewelerStoreName;
  final int originalTotalPriceMinorUnits;
  final int depositAmountMinorUnits;
  final int remainingBalanceMinorUnits;
  final String? paymobTransactionId;
  final String? paymobOrderId;
  final String status;
  final DateTime createdAt;
  final DateTime expiresAt;

  String get statusLabel => switch (status) {
    'reserved_for_48_hours' => 'Reserved for 48 hours',
    'handed_to_user' => 'Handed to you',
    'refunded_deposit' => 'Deposit refunded',
    'user_didnt_pick_up' => 'Not collected',
    _ => 'Status unavailable',
  };

  static String? _string(dynamic value) {
    return value is String && value.trim().isNotEmpty ? value.trim() : null;
  }

  static int _int(dynamic value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime _date(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }
}
