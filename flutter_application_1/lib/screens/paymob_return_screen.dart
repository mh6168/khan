import 'dart:async';

import 'package:flutter/material.dart';

import '../data/investment_service.dart';
import '../data/paymob_service.dart';
import '../khan_colors.dart';
import 'customer_home_screen.dart';

class PaymobReturnData {
  const PaymobReturnData({
    required this.orderId,
    required this.transactionId,
    required this.wasCancelled,
  });

  final String orderId;
  final String? transactionId;
  final bool wasCancelled;

  static PaymobReturnData? fromUri(Uri uri) {
    final orderId = uri.queryParameters['khan_order_id']?.trim();
    if (orderId == null ||
        orderId.isEmpty ||
        !RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(orderId)) {
      return null;
    }

    String? transactionId;
    for (final key in const ['id', 'transaction_id', 'txn_id', 'payment_id']) {
      final value = uri.queryParameters[key]?.trim();
      if (value != null && value.isNotEmpty) {
        transactionId = value;
        break;
      }
    }
    return PaymobReturnData(
      orderId: orderId,
      transactionId: transactionId,
      wasCancelled:
          uri.queryParameters['cancelled']?.toLowerCase() == 'true' ||
          uri.queryParameters['status']?.toLowerCase() == 'cancelled',
    );
  }
}

class PaymobReturnScreen extends StatefulWidget {
  const PaymobReturnScreen({
    super.key,
    required this.callback,
    required this.customerId,
    this.customerName,
    this.customerEmail,
    this.investmentService,
    this.paymobService,
  });

  final PaymobReturnData callback;
  final String customerId;
  final String? customerName;
  final String? customerEmail;
  final InvestmentService? investmentService;
  final PaymobService? paymobService;

  @override
  State<PaymobReturnScreen> createState() => _PaymobReturnScreenState();
}

class _PaymobReturnScreenState extends State<PaymobReturnScreen> {
  late final InvestmentService _investments =
      widget.investmentService ?? InvestmentService();
  late final PaymobService _paymob = widget.paymobService ?? PaymobService();
  _ReturnStatus _status = _ReturnStatus.verifying;
  String _message = 'Checking the payment directly with Paymob...';

  @override
  void initState() {
    super.initState();
    unawaited(_verifyAndComplete());
  }

  Future<void> _verifyAndComplete() async {
    _setStatus(
      _ReturnStatus.verifying,
      'Checking the payment directly with Paymob...',
    );
    final transactionId = widget.callback.transactionId;
    if (transactionId == null) {
      await _releasePendingOrder();
      _setStatus(
        widget.callback.wasCancelled
            ? _ReturnStatus.cancelled
            : _ReturnStatus.failed,
        widget.callback.wasCancelled
            ? 'The payment was cancelled. No investment was credited.'
            : 'Paymob did not return a transaction reference. No investment was credited.',
      );
      return;
    }

    try {
      final order = await _investments.getPurchaseOrder(
        widget.callback.orderId,
      );
      if (order.status == 'cancelled') {
        _setStatus(
          _ReturnStatus.cancelled,
          'This purchase was cancelled. No investment was credited.',
        );
        return;
      }
      if (order.status != 'pending' &&
          !(order.status == 'completed' &&
              order.paymentTransactionId == transactionId)) {
        throw StateError('This purchase is no longer available for payment.');
      }

      PaymobVerificationResult? result;
      Object? verificationError;
      for (var attempt = 0; attempt < 3; attempt++) {
        try {
          result = await _paymob.verifyTransaction(
            transactionId: transactionId,
            expectedMerchantOrderId: order.merchantOrderId,
            expectedAmountMinor: order.amountMinor,
          );
          verificationError = null;
          if (result.status != PaymobVerificationStatus.pending) break;
        } catch (error) {
          verificationError = error;
          result = null;
        }
        if (attempt < 2) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }

      if (verificationError != null) {
        _setStatus(
          _ReturnStatus.pending,
          'Paymob could not verify this transaction yet. No investment was credited. '
          '$verificationError',
        );
        return;
      }
      if (result?.status == PaymobVerificationStatus.pending) {
        _setStatus(
          _ReturnStatus.pending,
          'Paymob still reports this payment as pending. No investment was credited.',
        );
        return;
      }
      if (result?.status != PaymobVerificationStatus.success ||
          result?.payment == null) {
        await _releasePendingOrder();
        _setStatus(
          widget.callback.wasCancelled
              ? _ReturnStatus.cancelled
              : _ReturnStatus.failed,
          widget.callback.wasCancelled
              ? 'The payment was cancelled. No investment was credited.'
              : 'Paymob did not confirm a successful payment. No investment was credited.',
        );
        return;
      }

      await _investments.completePurchase(
        orderId: order.id,
        payment: result!.payment!,
      );
      if (!mounted) return;
      await Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute(
          builder: (_) => PurchaseSuccessScreen(
            purchase: order,
            transactionId: transactionId,
            customerId: widget.customerId,
            customerName: widget.customerName,
            customerEmail: widget.customerEmail,
          ),
        ),
      );
    } catch (error) {
      _setStatus(
        _ReturnStatus.failed,
        'The payment could not be verified and recorded. No new investment was credited. $error',
      );
    }
  }

  Future<void> _releasePendingOrder() {
    return _investments.cancelPurchase(widget.callback.orderId);
  }

  void _setStatus(_ReturnStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _message = message;
    });
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
    final (title, icon, color) = switch (_status) {
      _ReturnStatus.verifying => ('Verifying payment', Icons.sync, Colors.blue),
      _ReturnStatus.pending => (
        'Payment pending',
        Icons.pending_outlined,
        Colors.orange,
      ),
      _ReturnStatus.failed => (
        'Payment not verified',
        Icons.error_outline,
        Colors.red,
      ),
      _ReturnStatus.cancelled => (
        'Purchase cancelled',
        Icons.cancel_outlined,
        Colors.grey,
      ),
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Paymob payment result')),
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
                  title,
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(_message, textAlign: TextAlign.center),
                if (_status == _ReturnStatus.verifying) ...[
                  const SizedBox(height: 20),
                  const CircularProgressIndicator(),
                ],
                if (_status != _ReturnStatus.verifying) ...[
                  const SizedBox(height: 20),
                  if (_status == _ReturnStatus.pending)
                    OutlinedButton(
                      onPressed: _verifyAndComplete,
                      child: const Text('Check payment again'),
                    ),
                  if (_status == _ReturnStatus.pending)
                    const SizedBox(height: 8),
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

class PurchaseSuccessScreen extends StatelessWidget {
  const PurchaseSuccessScreen({
    super.key,
    required this.purchase,
    required this.transactionId,
    required this.customerId,
    this.customerName,
    this.customerEmail,
  });

  final InvestmentPurchaseOrder purchase;
  final String transactionId;
  final String customerId;
  final String? customerName;
  final String? customerEmail;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Purchase successful')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text(
                  'Purchase successful',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                _receiptRow('Asset', purchase.unit.toUpperCase()),
                _receiptRow('Quantity', '${purchase.quantity}'),
                _receiptRow('Status', 'Verified by Paymob'),
                _receiptRow('Transaction ID', transactionId),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil<void>(
                      MaterialPageRoute(
                        builder: (_) => CustomerHomeScreen(
                          customerId: customerId,
                          customerName: customerName,
                          customerEmail: customerEmail,
                        ),
                      ),
                      (_) => false,
                    );
                  },
                  child: const Text('Return to Investment Center'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Flexible(child: Text(value, textAlign: TextAlign.end)),
        ],
      ),
    );
  }
}

enum _ReturnStatus { verifying, pending, failed, cancelled }
