import 'package:flutter/material.dart';

import '../../data/supabase_storage.dart';
import '../../khan_colors.dart';
import '../../models/jewelry_reservation.dart';

class ReservationDetailScreen extends StatelessWidget {
  const ReservationDetailScreen({super.key, required this.reservation});

  final JewelryReservation reservation;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Reservation details'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          if (reservation.productImagePath != null &&
              reservation.productImagePath!.trim().isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  publicSupabaseImageUrl(reservation.productImagePath!),
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: khanSecondaryDark,
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.diamond_outlined,
                      color: khanLightGold,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          if (reservation.productImagePath != null &&
              reservation.productImagePath!.trim().isNotEmpty)
            const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: khanGold.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reservation.productName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: khanDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    reservation.jewelerStoreName,
                    style: const TextStyle(color: khanSecondaryDark),
                  ),
                  const SizedBox(height: 16),
                  _row('Status', reservation.statusLabel),
                  _row(
                    'Original total',
                    '${(reservation.originalTotalPriceMinorUnits / 100).toStringAsFixed(2)} EGP',
                  ),
                  _row(
                    'Deposit paid',
                    '${(reservation.depositAmountMinorUnits / 100).toStringAsFixed(2)} EGP',
                  ),
                  _row(
                    'Remaining balance',
                    '${(reservation.remainingBalanceMinorUnits / 100).toStringAsFixed(2)} EGP',
                  ),
                  _row('Reserved', _formatDate(reservation.createdAt)),
                  _row('Expires', _formatDate(reservation.expiresAt)),
                  if (reservation.paymobTransactionId != null)
                    _row(
                      'Paymob transaction',
                      reservation.paymobTransactionId!,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: khanLightGold,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Pay the remaining balance directly to the jeweler when '
                'collecting your order at the jeweler store. KHAN does not '
                'provide delivery. The 48-hour reservation deposit is '
                'non-refundable if the product is not collected.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: const TextStyle(color: khanSecondaryDark),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                color: khanDark,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    if (date.microsecondsSinceEpoch == 0) return 'Date unavailable';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
