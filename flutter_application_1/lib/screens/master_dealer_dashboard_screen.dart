import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/investment_service.dart';
import '../khan_colors.dart';
import '../models/investment.dart';
import '../models/investment_sell_request.dart';

class MasterDealerDashboardScreen extends StatefulWidget {
  const MasterDealerDashboardScreen({super.key});

  @override
  State<MasterDealerDashboardScreen> createState() =>
      _MasterDealerDashboardScreenState();
}

class _MasterDealerDashboardScreenState
    extends State<MasterDealerDashboardScreen> {
  final _service = InvestmentService();
  late final Stream<List<InvestmentSellRequest>> _requests = _service
      .watchMasterDealerSellRequests();
  String? _processingRequestId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Master Dealer Dashboard'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
        actions: [
          IconButton(
            tooltip: 'Sign out',
            onPressed: FirebaseAuth.instance.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 980),
            child: StreamBuilder<List<InvestmentSellRequest>>(
              stream: _requests,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Buyback requests could not be loaded: ${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data ?? const [];
                return ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    Text(
                      'Buyback Requests',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: khanDark,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Transfer the displayed payout manually through InstaPay, '
                      'then confirm the transfer to finalize the sale.',
                    ),
                    const SizedBox(height: 18),
                    if (requests.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text('There are no buyback requests yet.'),
                        ),
                      )
                    else
                      for (final request in requests)
                        _requestCard(context, request),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _requestCard(BuildContext context, InvestmentSellRequest request) {
    final processing = request.status == InvestmentSellRequestStatus.processing;
    final busy = _processingRequestId == request.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Buyback ${request.id}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: khanDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _statusBadge(
                  request.statusLabel,
                  processing ? Colors.orange : Colors.green.shade700,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _detailRow('Customer', _fallback(request.customerName)),
            _detailRow('Customer UID', request.customerUid),
            _detailRow('Customer email', _fallback(request.customerEmail)),
            _detailRow('Customer phone', _fallback(request.customerPhone)),
            const Divider(height: 22),
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'InstaPay receiving number',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy phone number',
                  onPressed: () => _copyPhone(request.instapayPhone),
                  icon: const Icon(Icons.copy),
                ),
              ],
            ),
            SelectableText(
              request.instapayPhone,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: khanDark,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 12),
            _quantityPriceRow(
              'LIRA',
              request.liraQuantity,
              request.liraUnitPriceMinor,
            ),
            _quantityPriceRow(
              'PARA',
              request.paraQuantity,
              request.paraUnitPriceMinor,
            ),
            const Divider(height: 24),
            Text(
              'Total payout  ${formatEgpMinor(request.totalPayoutMinor)}',
              style: Theme.of(context).textTheme.titleLarge
                  ?.copyWith(color: khanDark, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            _detailRow('Submitted', _formatDate(request.createdAt)),
            if (request.transferredAt != null)
              _detailRow('Transferred', _formatDate(request.transferredAt)),
            if (processing) ...[
              const SizedBox(height: 14),
              FilledButton.icon(
                onPressed: busy ? null : () => _confirmTransfer(request),
                icon: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: const Text('Mark Money Transferred'),
                style: FilledButton.styleFrom(
                  backgroundColor: khanDark,
                  foregroundColor: khanLightGold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _confirmTransfer(InvestmentSellRequest request) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm money transfer'),
        content: Text(
          'Confirm that ${formatEgpMinor(request.totalPayoutMinor)} was '
          'transferred through InstaPay to ${request.instapayPhone}? '
          'This finalizes the sale and updates both holdings and inventory.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm transfer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _processingRequestId = request.id);
    try {
      await _service.markSellRequestMoneyTransferred(request.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transfer confirmed and buyback finalized.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not confirm transfer: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _processingRequestId = null);
    }
  }

  Future<void> _copyPhone(String phone) async {
    await Clipboard.setData(ClipboardData(text: phone));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('InstaPay number copied.')));
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(color: khanSecondaryDark),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quantityPriceRow(String unit, int quantity, int unitPriceMinor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unit quantity: $quantity',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'Locked price: ${formatEgpMinor(unitPriceMinor)} / $unit',
            style: const TextStyle(color: khanSecondaryDark),
          ),
        ],
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

  String _fallback(String value) => value.isEmpty ? 'Not provided' : value;

  String _formatDate(DateTime? value) {
    if (value == null) return 'Waiting for timestamp';
    final local = value.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }
}
