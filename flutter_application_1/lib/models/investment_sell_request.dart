import 'package:cloud_firestore/cloud_firestore.dart';

enum InvestmentSellRequestStatus { processing, moneyTransferred }

class InvestmentSellRequest {
  const InvestmentSellRequest({
    required this.id,
    required this.customerUid,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.instapayPhone,
    required this.liraQuantity,
    required this.paraQuantity,
    required this.liraUnitPriceMinor,
    required this.paraUnitPriceMinor,
    required this.totalPayoutMinor,
    required this.status,
    required this.createdAt,
    this.transferredAt,
  });

  factory InvestmentSellRequest.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data() ?? const <String, dynamic>{};
    final status = switch (data['status']) {
      'processing' => InvestmentSellRequestStatus.processing,
      'money_transferred' => InvestmentSellRequestStatus.moneyTransferred,
      _ => throw FormatException(
        'Unknown sell request status in ${document.id}.',
      ),
    };
    return InvestmentSellRequest(
      id: document.id,
      customerUid: data['customerUid']?.toString() ?? '',
      customerName: data['customerName']?.toString() ?? '',
      customerEmail: data['customerEmail']?.toString() ?? '',
      customerPhone: data['customerPhone']?.toString() ?? '',
      instapayPhone: data['instapayPhone']?.toString() ?? '',
      liraQuantity: _intValue(data['liraQuantity']),
      paraQuantity: _intValue(data['paraQuantity']),
      liraUnitPriceMinor: _intValue(data['liraUnitPriceMinor']),
      paraUnitPriceMinor: _intValue(data['paraUnitPriceMinor']),
      totalPayoutMinor: _intValue(data['totalPayoutMinor']),
      status: status,
      createdAt: _dateValue(data['createdAt']),
      transferredAt: _dateValue(data['transferredAt']),
    );
  }

  final String id;
  final String customerUid;
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String instapayPhone;
  final int liraQuantity;
  final int paraQuantity;
  final int liraUnitPriceMinor;
  final int paraUnitPriceMinor;
  final int totalPayoutMinor;
  final InvestmentSellRequestStatus status;
  final DateTime? createdAt;
  final DateTime? transferredAt;

  String get statusLabel => switch (status) {
    InvestmentSellRequestStatus.processing => 'Processing',
    InvestmentSellRequestStatus.moneyTransferred => 'Money Transferred',
  };
}

int _intValue(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

DateTime? _dateValue(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  return null;
}
