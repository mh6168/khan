import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/investment_service.dart';
import '../data/paymob_service.dart';
import '../khan_colors.dart';
import '../models/investment.dart';
import '../widgets/khan_logo.dart';

class InvestmentPurchaseScreen extends StatefulWidget {
  const InvestmentPurchaseScreen({
    super.key,
    required this.initialUnit,
    required this.lira,
    required this.para,
  });

  final InvestmentUnit initialUnit;
  final InvestmentUnit lira;
  final InvestmentUnit para;

  @override
  State<InvestmentPurchaseScreen> createState() =>
      _InvestmentPurchaseScreenState();
}

class _InvestmentPurchaseScreenState extends State<InvestmentPurchaseScreen> {
  late InvestmentUnit _selectedUnit;
  final _quantityController = TextEditingController();
  final _service = InvestmentService();
  final _paymob = PaymobService();
  bool _loading = false;
  String? _orderId;
  Uri? _checkoutUrl;
  _PaymentStatus _paymentStatus = _PaymentStatus.idle;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  int get _totalMinor => _quantity * _selectedUnit.purchaseMinor;
  bool get _hasOpenOrder =>
      _orderId != null && _paymentStatus != _PaymentStatus.cancelled;

  String? get _validationError {
    if (_quantity <= 0) return 'Enter a quantity greater than zero.';
    if (_quantity > _selectedUnit.availableQuantity) {
      return 'Only ${_selectedUnit.availableQuantity} units are available.';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Purchase preview'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                const KhanLogo(width: 92, height: 34),
                const SizedBox(height: 22),
                Text(
                  'Purchase precious metals',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 24),
                SegmentedButton<InvestmentUnit>(
                  segments: [
                    ButtonSegment(
                      value: widget.lira,
                      label: const Text('LIRA'),
                    ),
                    ButtonSegment(
                      value: widget.para,
                      label: const Text('PARA'),
                    ),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: _loading || _hasOpenOrder
                      ? null
                      : (selection) {
                          setState(() {
                            _selectedUnit = selection.first;
                          });
                        },
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _quantityController,
                  onChanged: (_) => setState(() {}),
                  enabled: !_loading && !_hasOpenOrder,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: InputDecoration(
                    labelText: 'Quantity',
                    suffixText: _selectedUnit.name,
                    helperText:
                        'Available: ${_selectedUnit.availableQuantity} units',
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: khanDark,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      _priceRow(
                        context,
                        'Buy price',
                        _selectedUnit.purchaseLabel,
                      ),
                      const SizedBox(height: 10),
                      _priceRow(
                        context,
                        'Sell-back price',
                        _selectedUnit.buybackLabel,
                      ),
                      const SizedBox(height: 14),
                      Divider(color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 7),
                      _priceRow(context, 'Total', formatEgpMinor(_totalMinor)),
                    ],
                  ),
                ),
                if (_validationError != null &&
                    _quantityController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      _validationError!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed:
                        _loading || _validationError != null || _hasOpenOrder
                        ? null
                        : _continueToPaymob,
                    style: FilledButton.styleFrom(
                      backgroundColor: khanDark,
                      foregroundColor: khanGold,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Create Paymob checkout'),
                  ),
                ),
                if (_orderId != null ||
                    _paymentStatus == _PaymentStatus.failed) ...[
                  const SizedBox(height: 18),
                  _paymentStatusCard(context),
                  if (_checkoutUrl != null &&
                      _paymentStatus != _PaymentStatus.cancelled) ...[
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _loading ? null : _openCheckout,
                      child: Text(
                        _paymentStatus == _PaymentStatus.pending
                            ? 'Open Paymob checkout again'
                            : 'Open Paymob checkout',
                      ),
                    ),
                  ],
                  if (_orderId != null &&
                      _paymentStatus != _PaymentStatus.cancelled) ...[
                    TextButton(
                      onPressed: _loading ? null : _cancelPurchase,
                      child: const Text('Cancel this purchase'),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'DEMO ONLY: Paymob credentials are used by this client app '
                    'and checkout records are client-writable. Do not use for '
                    'real payments or deploy publicly.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _paymentStatusCard(BuildContext context) {
    final (label, color, icon) = switch (_paymentStatus) {
      _PaymentStatus.creating => (
        'Creating Paymob checkout',
        Colors.blue,
        Icons.hourglass_top,
      ),
      _PaymentStatus.pending => (
        'Payment pending',
        Colors.orange,
        Icons.pending_outlined,
      ),
      _PaymentStatus.ready => (
        'Checkout ready',
        Colors.blue,
        Icons.open_in_new,
      ),
      _PaymentStatus.failed => (
        'Payment not verified',
        Colors.red,
        Icons.error_outline,
      ),
      _PaymentStatus.cancelled => (
        'Purchase cancelled',
        Colors.grey,
        Icons.cancel_outlined,
      ),
      _PaymentStatus.idle => ('Payment not started', Colors.grey, Icons.info),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(color: color, fontWeight: FontWeight.w700),
                ),
                if (_statusMessage != null) ...[
                  const SizedBox(height: 4),
                  Text(_statusMessage!),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _priceRow(BuildContext context, String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: Colors.white.withValues(alpha: 0.74)),
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: khanLightGold, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Future<void> _continueToPaymob() async {
    final unit = _selectedUnit.name.toLowerCase();
    final quantity = _quantity;
    final unitPriceMinor = _selectedUnit.purchaseMinor;
    final amountMinor = quantity * unitPriceMinor;
    setState(() => _loading = true);
    String? orderId;
    try {
      orderId = await _service.createPendingPurchase(
        unit: unit,
        quantity: quantity,
        unitPriceMinor: unitPriceMinor,
      );
      if (!mounted) {
        await _service.cancelPurchase(orderId);
        return;
      }
      final merchantOrderId = 'khan-md-$orderId';
      setState(() {
        _orderId = orderId;
        _checkoutUrl = null;
        _paymentStatus = _PaymentStatus.creating;
        _statusMessage = null;
      });
      final session = await _paymob.createCheckoutSession(
        amountMinor: amountMinor,
        merchantOrderId: merchantOrderId,
        email: FirebaseAuth.instance.currentUser?.email ?? '',
        returnUrl: kIsWeb ? _paymobReturnUrl(orderId) : null,
      );
      await _service.attachPaymobOrder(
        orderId: orderId,
        paymobOrderId: session.paymobOrderId,
      );
      if (!mounted) {
        await _service.cancelPurchase(orderId);
        return;
      }
      setState(() {
        _checkoutUrl = session.checkoutUrl;
        _paymentStatus = _PaymentStatus.ready;
        _statusMessage =
            'Checkout is ready. Open it in a new tab. Paymob will return to '
            'KHAN and verify the payment automatically.';
      });
    } catch (error) {
      Object? cleanupError;
      if (orderId != null) {
        try {
          await _service.cancelPurchase(orderId);
        } catch (cleanupFailure) {
          cleanupError = cleanupFailure;
        }
      }
      if (mounted) {
        setState(() {
          _paymentStatus = _PaymentStatus.failed;
          _statusMessage = cleanupError == null
              ? error.toString()
              : '$error; reservation cleanup also failed: $cleanupError';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openCheckout() async {
    final checkoutUrl = _checkoutUrl;
    if (checkoutUrl == null) return;
    setState(() => _loading = true);
    try {
      final opened = await launchUrl(
        checkoutUrl,
        mode: LaunchMode.externalApplication,
      );
      if (!mounted) return;
      setState(() {
        _paymentStatus = opened
            ? _PaymentStatus.pending
            : _PaymentStatus.failed;
        _statusMessage = opened
            ? 'Waiting for Paymob to return the payment result. Verification '
                  'and portfolio updates happen automatically.'
            : 'Could not open the Paymob checkout page. Try opening it again.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _paymentStatus = _PaymentStatus.failed;
          _statusMessage = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _paymobReturnUrl(String orderId) {
    final parameters = Map<String, String>.from(Uri.base.queryParameters)
      ..removeWhere(
        (key, _) => const {
          'khan_order_id',
          'id',
          'transaction_id',
          'txn_id',
          'success',
          'pending',
        }.contains(key),
      )
      ..['khan_order_id'] = orderId;
    return Uri.base.replace(queryParameters: parameters).toString();
  }

  Future<void> _cancelPurchase() async {
    final orderId = _orderId;
    if (orderId == null) return;
    setState(() => _loading = true);
    try {
      await _service.cancelPurchase(orderId);
      if (!mounted) return;
      setState(() {
        _paymentStatus = _PaymentStatus.cancelled;
        _statusMessage = 'The pending inventory reservation was released.';
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _paymentStatus = _PaymentStatus.failed;
          _statusMessage = error.toString();
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

enum _PaymentStatus { idle, creating, ready, pending, failed, cancelled }
