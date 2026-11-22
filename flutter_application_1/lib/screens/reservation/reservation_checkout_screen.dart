import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/paymob_service.dart';
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
  final PaymobService _paymob = PaymobService();
  late Future<ReservationQuote> _quoteFuture;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    try {
      _quoteFuture = Future.value(
        ReservationQuote.fromProduct(widget.product, widget.jeweler),
      );
    } catch (error, stackTrace) {
      _quoteFuture = Future.error(error, stackTrace);
    }
  }

  Future<void> _proceed() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    ReservationCheckout? checkout;
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw StateError('Sign in required.');
      final quote = await _quoteFuture;
      checkout = await _service.createCheckout(
        product: widget.product,
        quote: quote,
        customerName: user.displayName,
        customerEmail: user.email,
        customerPhone: user.phoneNumber,
      );
      final session = await _paymob.createCheckoutSession(
        amountMinor: checkout.depositMinor,
        merchantOrderId: checkout.merchantOrderId,
        email: user.email ?? '',
        returnUrl: kIsWeb ? _reservationReturnUrl(checkout.orderId) : null,
      );
      await _service.attachPaymobOrder(
        orderId: checkout.orderId,
        paymobOrderId: session.paymobOrderId,
      );
      if (!mounted) {
        await _service.cancelCheckout(checkout.orderId);
        return;
      }
      final opened = await launchUrl(
        session.checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!opened) {
        await _service.cancelCheckout(checkout.orderId);
        if (mounted) {
          setState(() => _error = 'Could not open the Paymob checkout page.');
        }
      }
    } catch (error) {
      Object? cleanupError;
      if (checkout != null) {
        try {
          await _service.cancelCheckout(checkout.orderId);
        } catch (failure) {
          cleanupError = failure;
        }
      }
      if (mounted) {
        setState(() {
          _error = cleanupError == null
              ? error.toString()
              : '$error; checkout cleanup also failed: $cleanupError';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _reservationReturnUrl(String orderId) {
    final parameters = Map<String, String>.from(Uri.base.queryParameters)
      ..removeWhere(
        (key, _) => const {
          'khan_reservation_order_id',
          'id',
          'transaction_id',
          'txn_id',
          'payment_id',
          'success',
          'pending',
          'cancelled',
          'status',
        }.contains(key),
      )
      ..['khan_reservation_order_id'] = orderId;
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
                      if (widget.product.imageUrls.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: Image.network(
                              widget.product.imageUrls.first,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
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
                      if (widget.product.imageUrls.isNotEmpty)
                        const SizedBox(height: 16),
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
                  'Pay 10% now to reserve this piece for 48 hours. '
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
