import 'package:flutter/material.dart';

import '../../khan_colors.dart';
import '../../models/jewelry_product.dart';
import '../../models/jeweler_profile.dart';
import 'reservation_checkout_screen.dart';

class ReservationPaymentMethodScreen extends StatelessWidget {
  const ReservationPaymentMethodScreen({
    super.key,
    required this.product,
    this.jeweler,
  });

  final JewelryProduct product;
  final JewelerProfile? jeweler;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Reservation payment'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Choose payment method',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Choose how you want to pay the 10% reservation deposit.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: khanSecondaryDark),
              ),
              const SizedBox(height: 20),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ReservationCheckoutScreen(
                        product: product,
                        jeweler: jeweler,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: khanGold.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.credit_card_rounded,
                            color: khanSecondaryDark,
                          ),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paymob Gateway',
                                style: TextStyle(
                                  color: khanDark,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Pay securely with Paymob',
                                style: TextStyle(color: khanSecondaryDark),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
