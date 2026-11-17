import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/investment_service.dart';
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
  final _transactionController = TextEditingController();
  final _service = InvestmentService();
  bool _loading = false;
  String? _orderId;

  @override
  void initState() {
    super.initState();
    _selectedUnit = widget.initialUnit;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _transactionController.dispose();
    super.dispose();
  }

  int get _quantity => int.tryParse(_quantityController.text.trim()) ?? 0;

  int get _totalMinor => _quantity * _selectedUnit.purchaseMinor;

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
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedUnit = selection.first;
                      _orderId = null;
                    });
                  },
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _quantityController,
                  onChanged: (_) => setState(() {}),
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
                    onPressed: _loading || _validationError != null
                        ? null
                        : _continueToPaymob,
                    style: FilledButton.styleFrom(
                      backgroundColor: khanDark,
                      foregroundColor: khanGold,
                    ),
                    child: _loading
                        ? const CircularProgressIndicator()
                        : const Text('Continue to Paymob'),
                  ),
                ),
                if (_orderId != null) ...[
                  const SizedBox(height: 18),
                  TextField(
                    controller: _transactionController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Paymob transaction ID',
                      hintText: 'Enter the ID after checkout',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: _loading ? null : _confirmPayment,
                    child: const Text('Confirm successful payment'),
                  ),
                ],
              ],
            ),
          ),
        ),
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
    setState(() => _loading = true);
    try {
      final result = await _service.createPurchase(
        unit: _selectedUnit.name.toLowerCase(),
        quantity: _quantity,
      );
      if (!mounted) return;
      setState(() => _orderId = result['orderId'] as String);
      final url = result['checkoutUrl'] as String?;
      if (url != null && await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        _showMessage('The payment checkout could not be opened.');
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmPayment() async {
    final transactionId = _transactionController.text.trim();
    if (_orderId == null || transactionId.isEmpty) {
      _showMessage('Enter the Paymob transaction ID.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _service.confirmPurchase(
        orderId: _orderId!,
        paymobTransactionId: transactionId,
      );
      if (!mounted) return;
      _showMessage('Payment verified. Your portfolio is updated.');
      Navigator.of(context).pop();
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
