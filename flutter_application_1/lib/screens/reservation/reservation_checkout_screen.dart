import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/reservation_service.dart';
import '../../khan_colors.dart';
import '../../models/jeweler_profile.dart';
import '../../models/jewelry_product.dart';

class ReservationCheckoutScreen extends StatefulWidget {
  const ReservationCheckoutScreen({
    super.key,
    required this.product,
    this.jeweler,
  });

  final JewelryProduct product;
  final JewelerProfile? jeweler;

  @override
  State<ReservationCheckoutScreen> createState() =>
      _ReservationCheckoutScreenState();
}

class _ReservationCheckoutScreenState extends State<ReservationCheckoutScreen> {
  final ReservationService _service = ReservationService();
  late Future<ReservationQuote> _quoteFuture;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _quoteFuture = _service.getQuote(widget.product.id);
  }

  Future<void> _proceed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final checkout = await _service.createCheckout(
        productId: widget.product.id,
        returnUrl: kIsWeb ? _reservationReturnUrl : null,
      );
      if (!mounted) {
        await _service.cancelCheckout(checkout.orderId);
        return;
      }
      final opened = await launchUrl(
        checkout.checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened && mounted) {
        setState(() => _error = 'Could not open the Paymob checkout page.');
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _reservationReturnUrl {
    final parameters = Map<String, String>.from(Uri.base.queryParameters);
    parameters.remove('khan_reservation_order_id');
    return Uri.base.replace(queryParameters: parameters).toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Reservation checkout'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: FutureBuilder<ReservationQuote>(
        future: _quoteFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _errorView(snapshot.error.toString());
          }
          final quote = snapshot.data;
          if (quote == null) return _errorView('Price unavailable.');
          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: khanGold.withValues(alpha: 0.35)),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        quote.productName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: khanDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        quote.jewelerStoreName,
                        style: const TextStyle(color: khanSecondaryDark),
                      ),
                      const SizedBox(height: 16),
                      _priceRow(
                        context,
                        'Current total product price',
                        '${(quote.totalMinor / 100).toStringAsFixed(2)} EGP',
                      ),
                      _priceRow(
                        context,
                        'Deposit (10%)',
                        '${(quote.depositMinor / 100).toStringAsFixed(2)} EGP',
                      ),
                      _priceRow(
                        context,
                        'Remaining (90%)',
                        '${(quote.remainingMinor / 100).toStringAsFixed(2)} EGP',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Container(
                constraints: const BoxConstraints(maxWidth: 620),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: khanLightGold,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Pay 10% now to reserve this jewelry piece for 48 hours. '
                  'The remaining balance will be paid directly to the jeweler '
                  'when collecting your order.',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 18),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 620),
                child: FilledButton(
                  onPressed: _loading ? null : _proceed,
                  style: FilledButton.styleFrom(
                    backgroundColor: khanDark,
                    foregroundColor: khanGold,
                    minimumSize: const Size.fromHeight(54),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Proceed to Paymob'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _errorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          const SizedBox(width: 12),
          Text(
            value,
            style: const TextStyle(
              color: khanDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
