import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/investment_service.dart';
import '../../khan_colors.dart';
import '../../models/investment.dart';
import '../../models/investment_sell_request.dart';

class SellInvestmentSection extends StatefulWidget {
  const SellInvestmentSection({
    super.key,
    required this.service,
    required this.portfolio,
    required this.liraPrices,
    required this.paraPrices,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
  });

  final InvestmentService service;
  final InvestmentPortfolio portfolio;
  final InvestmentPrices liraPrices;
  final InvestmentPrices paraPrices;
  final String customerName;
  final String customerEmail;
  final String customerPhone;

  @override
  State<SellInvestmentSection> createState() => _SellInvestmentSectionState();
}

class _SellInvestmentSectionState extends State<SellInvestmentSection> {
  final _phoneController = TextEditingController();
  final _liraController = TextEditingController();
  final _paraController = TextEditingController();
  late final Stream<List<InvestmentSellRequest>> _requests;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _requests = widget.service.watchCustomerSellRequests();
    _phoneController.text = widget.customerPhone;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _liraController.dispose();
    _paraController.dispose();
    super.dispose();
  }

  int get _liraQuantity => int.tryParse(_liraController.text.trim()) ?? 0;
  int get _paraQuantity => int.tryParse(_paraController.text.trim()) ?? 0;
  int get _estimatedPayout =>
      _liraQuantity * widget.liraPrices.buybackMinor +
      _paraQuantity * widget.paraPrices.buybackMinor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Sell investments',
          style: Theme.of(context).textTheme.titleLarge
              ?.copyWith(color: khanDark, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 6),
        Text(
          'Submit a sell request. The Master Dealer will transfer the payout '
          'through InstaPay and confirm it here.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.8)),
        ),
        const SizedBox(height: 14),
        _formCard(context),
        const SizedBox(height: 24),
        Text(
          'Sell request history',
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: khanDark, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        StreamBuilder<List<InvestmentSellRequest>>(
          stream: _requests,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return _historyMessage(
                'Sell requests could not be loaded: ${snapshot.error}',
              );
            }
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final requests = snapshot.data ?? const [];
            if (requests.isEmpty) {
              return _historyMessage('You have not submitted a sell request.');
            }
            return Column(
              children: [
                for (final request in requests) _requestCard(context, request),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _formCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: khanGold.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Available to sell',
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: Text('LIRA  ${widget.portfolio.liraQuantity}')),
              Expanded(child: Text('PARA  ${widget.portfolio.paraQuantity}')),
            ],
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _phoneController,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'InstaPay receiving mobile number',
              hintText: '01XXXXXXXXX',
              prefixIcon: Icon(Icons.phone_android),
            ),
          ),
          const SizedBox(height: 12),
          _quantityField(
            controller: _liraController,
            label: 'LIRA quantity',
            available: widget.portfolio.liraQuantity,
          ),
          const SizedBox(height: 8),
          Text(
            'Current sellback price: '
            '${formatEgpMinor(widget.liraPrices.buybackMinor)} per LIRA',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          _quantityField(
            controller: _paraController,
            label: 'PARA quantity',
            available: widget.portfolio.paraQuantity,
          ),
          const SizedBox(height: 8),
          Text(
            'Current sellback price: '
            '${formatEgpMinor(widget.paraPrices.buybackMinor)} per PARA',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: khanDark,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Estimated payout',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  formatEgpMinor(_estimatedPayout),
                  style: const TextStyle(
                    color: khanLightGold,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
          ],
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _submitting ? null : _reviewRequest,
            icon: _submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.receipt_long_outlined),
            label: const Text('Review sell request'),
            style: FilledButton.styleFrom(
              backgroundColor: khanDark,
              foregroundColor: khanLightGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityField({
    required TextEditingController controller,
    required String label,
    required int available,
  }) {
    return TextField(
      controller: controller,
      enabled: !_submitting && available > 0,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (_) => setState(() {
        _errorMessage = null;
      }),
      decoration: InputDecoration(
        labelText: label,
        helperText: 'Available: $available',
        suffixText: 'units',
      ),
    );
  }

  Future<void> _reviewRequest() async {
    final phone = InvestmentService.normalizeEgyptianMobile(
      _phoneController.text,
    );
    if (phone == null) {
      setState(() => _errorMessage = 'Enter a valid Egyptian mobile number.');
      return;
    }
    if (_liraQuantity < 0 ||
        _paraQuantity < 0 ||
        (_liraQuantity == 0 && _paraQuantity == 0)) {
      setState(
        () => _errorMessage =
            'Enter a positive quantity for at least one investment.',
      );
      return;
    }
    if (_liraQuantity > widget.portfolio.liraQuantity ||
        _paraQuantity > widget.portfolio.paraQuantity) {
      setState(
        () => _errorMessage =
            'A requested quantity exceeds your available holdings.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Review sell request'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('InstaPay phone: $phone'),
            Text('LIRA: $_liraQuantity'),
            Text('PARA: $_paraQuantity'),
            const SizedBox(height: 8),
            Text(
              'Estimated payout: ${formatEgpMinor(_estimatedPayout)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your units will be reserved now and deducted only after the '
              'Master Dealer confirms the transfer.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Edit request'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Submit request'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });
    try {
      await widget.service.createSellRequest(
        liraQuantity: _liraQuantity,
        paraQuantity: _paraQuantity,
        instapayPhone: phone,
        liraUnitPriceMinor: widget.liraPrices.buybackMinor,
        paraUnitPriceMinor: widget.paraPrices.buybackMinor,
        customerName: widget.customerName,
        customerEmail: widget.customerEmail,
        customerPhone: widget.customerPhone,
      );
      if (!mounted) return;
      _liraController.clear();
      _paraController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sell request submitted for processing.')),
      );
    } catch (error) {
      if (mounted) setState(() => _errorMessage = error.toString());
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Widget _requestCard(BuildContext context, InvestmentSellRequest request) {
    final transferred =
        request.status == InvestmentSellRequestStatus.moneyTransferred;
    final statusColor = transferred ? Colors.green.shade700 : Colors.orange;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Request ${request.id}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                _statusBadge(request.statusLabel, statusColor),
              ],
            ),
            const SizedBox(height: 8),
            Text('Submitted: ${_formatDate(request.createdAt)}'),
            Text(
              'LIRA: ${request.liraQuantity}  ·  PARA: ${request.paraQuantity}',
            ),
            Text('InstaPay: ${request.instapayPhone}'),
            const SizedBox(height: 4),
            Text(
              'Expected payout: ${formatEgpMinor(request.totalPayoutMinor)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            if (request.transferredAt != null)
              Text('Transferred: ${_formatDate(request.transferredAt)}'),
          ],
        ),
      ),
    );
  }

  Widget _historyMessage(String message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(color: khanSecondaryDark),
      ),
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }

  String _formatDate(DateTime? value) {
    if (value == null) return 'Waiting for timestamp';
    final local = value.toLocal();
    final date =
        '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
    final time =
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
    return '$date $time';
  }
}
