import 'package:flutter/material.dart';

import '../../data/reservation_service.dart';
import '../../khan_colors.dart';
import '../../models/jewelry_reservation.dart';
import '../../widgets/reservation_card.dart';
import 'reservation_detail_screen.dart';

class MyOrdersScreen extends StatelessWidget {
  const MyOrdersScreen({super.key, required this.customerId});

  final String customerId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('My Orders'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: StreamBuilder<List<JewelryReservation>>(
        stream: ReservationService().watchMyReservations(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Reservations could not be loaded. Please try again.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: Colors.red.shade700),
                ),
              ),
            );
          }
          final reservations = snapshot.data ?? const <JewelryReservation>[];
          if (reservations.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.receipt_long_outlined,
                      size: 52,
                      color: khanGold,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No reservations yet',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: khanDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Reserved jewelry pieces will appear here.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: reservations.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final reservation = reservations[index];
              return ReservationCard(
                reservation: reservation,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ReservationDetailScreen(reservation: reservation),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
