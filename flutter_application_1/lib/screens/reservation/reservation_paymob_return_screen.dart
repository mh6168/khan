import 'dart:async';

import 'package:flutter/material.dart';

import '../../data/reservation_service.dart';
import '../../khan_colors.dart';
import '../customer_home_screen.dart';

class ReservationPaymobReturnScreen extends StatefulWidget {
  const ReservationPaymobReturnScreen({
    super.key,
    required this.orderId,
    required this.customerId,
    this.transactionId,
    this.wasCancelled = false,
    this.customerName,
    this.customerEmail,
  });

  final String orderId;
  final String customerId;
  final String? transactionId;
  final bool wasCancelled;
  final String? customerName;
  final String? customerEmail;

  @override
  State<ReservationPaymobReturnScreen> createState() =>
      _ReservationPaymobReturnScreenState();
}

class _ReservationPaymobReturnScreenState
    extends State<ReservationPaymobReturnScreen> {
  final ReservationService _service = ReservationService();
  String _status = 'verifying';
  String _message = 'Checking the reservation payment with Paymob...';

  @override
  void initState() {
    super.initState();
    unawaited(_verify());
  }

  Future<void> _verify() async {
    if (widget.transactionId == null || widget.transactionId!.isEmpty) {
      await _service.cancelCheckout(widget.orderId);
      if (!mounted) return;
      setState(() {
        _status = widget.wasCancelled ? 'cancelled' : 'failed';
        _message = widget.wasCancelled
            ? 'The Paymob payment was cancelled.'
            : 'Paymob did not return a transaction reference.';
      });
      return;
    }
    try {
      final result = await _service.confirmPayment(
        orderId: widget.orderId,
        transactionId: widget.transactionId!,
      );
      if (!mounted) return;
      final status = result['status']?.toString() ?? 'failed';
      setState(() {
        _status = status;
        if (status == 'success') {
          _message = 'Deposit verified. Your reservation was created.';
        } else if (status == 'pending') {
          _message =
              'The payment is still pending. No reservation was created yet.';
        } else if (status == 'cancelled') {
          _message = 'The Paymob payment was cancelled.';
        } else {
          _message = 'Paymob did not confirm a successful deposit payment.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'failed';
        _message = 'The reservation payment could not be verified. $error';
      });
    }
  }

  void _returnHome() {
    Navigator.of(context).pushAndRemoveUntil<void>(
      MaterialPageRoute(
        builder: (_) => CustomerHomeScreen(
          customerId: widget.customerId,
          customerName: widget.customerName,
          customerEmail: widget.customerEmail,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSuccess = _status == 'success';
    final isPending = _status == 'pending';
    final isVerifying = _status == 'verifying';
    final icon = isSuccess
        ? Icons.check_circle_outline
        : isPending
        ? Icons.pending_outlined
        : _status == 'cancelled'
        ? Icons.cancel_outlined
        : isVerifying
        ? Icons.sync
        : Icons.error_outline;
    final color = isSuccess
        ? Colors.green
        : isPending
        ? Colors.orange
        : isVerifying
        ? Colors.blue
        : _status == 'cancelled'
        ? Colors.grey
        : Colors.red;
    return Scaffold(
      appBar: AppBar(title: const Text('Reservation payment')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 56, color: color),
                const SizedBox(height: 16),
                Text(
                  isVerifying
                      ? 'Verifying payment'
                      : isSuccess
                      ? 'Reservation confirmed'
                      : isPending
                      ? 'Payment pending'
                      : _status == 'cancelled'
                      ? 'Payment cancelled'
                      : 'Payment not confirmed',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                Text(_message, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                if (isVerifying) const CircularProgressIndicator(),
                if (!isVerifying) ...[
                  if (isPending)
                    OutlinedButton(
                      onPressed: _verify,
                      child: const Text('Check payment again'),
                    ),
                  if (isPending) const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _returnHome,
                    child: const Text('Return to KHAN'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
