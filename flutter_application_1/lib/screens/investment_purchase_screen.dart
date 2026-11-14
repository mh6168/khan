import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../khan_colors.dart';
import '../models/investment_demo_data.dart';
import '../widgets/investment/demo_data_badge.dart';
import '../widgets/khan_logo.dart';

class InvestmentPurchaseScreen extends StatefulWidget {
  const InvestmentPurchaseScreen({super.key, required this.initialUnit});

  final InvestmentUnitDemo initialUnit;

  @override
  State<InvestmentPurchaseScreen> createState() =>
      _InvestmentPurchaseScreenState();
}

class _InvestmentPurchaseScreenState extends State<InvestmentPurchaseScreen> {
  late InvestmentUnitDemo _selectedUnit;
  final _quantityController = TextEditingController(text: '10');

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

  @override
  Widget build(BuildContext context) {
    final demoTotal = _selectedUnit == liraDemo ? 'EGP 1,450.00' : 'EGP 420.00';

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
                Row(
                  children: [
                    const KhanLogo(width: 92, height: 34),
                    const Spacer(),
                    const DemoDataBadge(),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Build your metals preview',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'This visual-only form does not place an order or move money.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.78),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                _fieldLabel(context, 'SELECT A UNIT'),
                const SizedBox(height: 10),
                SegmentedButton<InvestmentUnitDemo>(
                  segments: const [
                    ButtonSegment(
                      value: liraDemo,
                      label: Text('LIRA'),
                      icon: Icon(Icons.monetization_on_outlined),
                    ),
                    ButtonSegment(
                      value: paraDemo,
                      label: Text('PARA'),
                      icon: Icon(Icons.auto_awesome_outlined),
                    ),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: (selection) {
                    setState(() => _selectedUnit = selection.first);
                  },
                  style: SegmentedButton.styleFrom(
                    foregroundColor: khanDark,
                    selectedForegroundColor: khanDark,
                    selectedBackgroundColor: khanLightGold,
                  ),
                ),
                const SizedBox(height: 22),
                _fieldLabel(context, 'QUANTITY'),
                const SizedBox(height: 9),
                TextField(
                  controller: _quantityController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter quantity',
                    suffixText: _selectedUnit.name,
                    prefixIcon: const Icon(Icons.tag_rounded, color: khanGold),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: khanGold.withValues(alpha: 0.24),
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: khanGold.withValues(alpha: 0.24),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: khanGold, width: 1.5),
                    ),
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
                        'Illustrative unit price',
                        _selectedUnit.priceLabel,
                      ),
                      const SizedBox(height: 14),
                      Divider(color: Colors.white.withValues(alpha: 0.15)),
                      const SizedBox(height: 7),
                      _priceRow(context, 'Estimated total · demo', demoTotal),
                      const SizedBox(height: 10),
                      Text(
                        'Fixed example for 10 units. The editable quantity '
                        'does not trigger a calculation.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.62),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 54,
                  child: FilledButton(
                    onPressed: _showDemoNotice,
                    style: FilledButton.styleFrom(
                      backgroundColor: khanDark,
                      foregroundColor: khanGold,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Continue · demo only',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Demonstration interface only. No transaction will be made.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(BuildContext context, String label) {
    return Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
        color: khanSecondaryDark,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.9,
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
        const SizedBox(width: 12),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall
              ?.copyWith(color: khanLightGold, fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  void _showDemoNotice() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: khanBackground,
        icon: const Icon(Icons.info_outline_rounded, color: khanGold, size: 34),
        title: const Text('Demonstration only'),
        content: const Text(
          'This preview is not connected to purchasing. No order has been '
          'placed and no money has been moved.',
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close preview'),
          ),
        ],
      ),
    );
  }
}
