import 'package:flutter/material.dart';

import '../data/investment_price_service.dart';
import '../data/investment_service.dart';
import '../khan_colors.dart';
import '../models/investment.dart';
import '../widgets/home_sections.dart';
import '../widgets/investment/lira_card.dart';
import '../widgets/investment/para_card.dart';
import '../widgets/investment/performance_chart.dart';
import '../widgets/investment/portfolio_overview.dart';
import '../widgets/investment/recent_activity.dart';
import 'investment_purchase_screen.dart';

class InvestScreen extends StatefulWidget {
  const InvestScreen({super.key, required this.header});

  final Widget header;

  @override
  State<InvestScreen> createState() => _InvestScreenState();
}

class _InvestScreenState extends State<InvestScreen> {
  final _service = InvestmentService();
  final _priceService = InvestmentPriceService();
  late Future<InvestmentPriceSnapshot> _pricesFuture;

  @override
  void initState() {
    super.initState();
    _pricesFuture = _priceService.fetchPrices();
  }

  Future<void> _refreshPrices() async {
    final request = _priceService.fetchPrices();
    setState(() => _pricesFuture = request);
    try {
      await request;
    } catch (_) {
      // FutureBuilder displays the request error in the screen.
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<InvestmentPriceSnapshot>(
      future: _pricesFuture,
      builder: (context, priceSnapshot) {
        if (priceSnapshot.connectionState == ConnectionState.waiting) {
          return _priceLoading();
        }
        if (priceSnapshot.hasError) {
          return _priceError(priceSnapshot.error.toString());
        }
        if (!priceSnapshot.hasData) {
          return _priceLoading();
        }
        return _buildInvestmentCenter(priceSnapshot.data!);
      },
    );
  }

  Widget _priceLoading() {
    return Column(
      children: [
        widget.header,
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading current gold and silver prices...'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _priceError(String message) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      children: [
        widget.header,
        const SizedBox(height: 40),
        const Icon(Icons.cloud_off_outlined, size: 44, color: khanGold),
        const SizedBox(height: 12),
        Text(
          'Unable to load current investment prices.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 16),
        Center(
          child: FilledButton.icon(
            onPressed: _refreshPrices,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCenter(InvestmentPriceSnapshot prices) {
    final lira = _investmentUnit(
      'LIRA',
      'Digital gold investment unit',
      '1 LIRA represents 0.01 grams of 24-karat gold.',
      prices.lira,
      Icons.monetization_on_outlined,
      const Color(0xFFB88C31),
    );
    final para = _investmentUnit(
      'PARA',
      'Digital silver investment unit',
      '1 PARA represents 1 gram of 925 silver.',
      prices.para,
      Icons.auto_awesome_outlined,
      const Color(0xFF658087),
    );

    return StreamBuilder<Map<String, int>>(
      stream: _service.watchInventory(),
      builder: (context, inventorySnapshot) {
        final inventory =
            inventorySnapshot.data ?? const {'lira': 0, 'para': 0};
        final availableLira = inventory['lira'] ?? 0;
        final availablePara = inventory['para'] ?? 0;
        final liraWithInventory = _withInventory(lira, availableLira);
        final paraWithInventory = _withInventory(para, availablePara);

        return StreamBuilder<InvestmentPortfolio>(
          stream: _service.watchPortfolio(),
          builder: (context, portfolioSnapshot) {
            final portfolio =
                portfolioSnapshot.data ?? const InvestmentPortfolio();
            final liraValueMinor =
                portfolio.liraQuantity * prices.lira.buybackMinor;
            final paraValueMinor =
                portfolio.paraQuantity * prices.para.buybackMinor;

            return StreamBuilder<List<double>>(
              stream: _service.watchPriceHistory(),
              builder: (context, historySnapshot) {
                final history = historySnapshot.data ?? const [];
                return StreamBuilder<List<InvestmentActivity>>(
                  stream: _service.watchActivity(),
                  builder: (context, activitySnapshot) {
                    final activities = activitySnapshot.data ?? const [];
                    return _screenContent(
                      lira: liraWithInventory,
                      para: paraWithInventory,
                      portfolio: portfolio,
                      liraValueMinor: liraValueMinor,
                      paraValueMinor: paraValueMinor,
                      history: history,
                      activities: activities,
                      priceUpdatedAt: prices.updatedAt,
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  InvestmentUnit _investmentUnit(
    String name,
    String description,
    String definition,
    InvestmentPrices prices,
    IconData icon,
    Color accent,
  ) {
    return InvestmentUnit(
      name: name,
      description: description,
      spotMinor: prices.spotMinor,
      purchaseMinor: prices.purchaseMinor,
      buybackMinor: prices.buybackMinor,
      availableQuantity: 0,
      icon: icon,
      accent: accent,
      definition: definition,
    );
  }

  InvestmentUnit _withInventory(InvestmentUnit unit, int quantity) {
    return InvestmentUnit(
      name: unit.name,
      description: unit.description,
      spotMinor: unit.spotMinor,
      purchaseMinor: unit.purchaseMinor,
      buybackMinor: unit.buybackMinor,
      availableQuantity: quantity,
      icon: unit.icon,
      accent: unit.accent,
      definition: unit.definition,
    );
  }

  Widget _screenContent({
    required InvestmentUnit lira,
    required InvestmentUnit para,
    required InvestmentPortfolio portfolio,
    required int liraValueMinor,
    required int paraValueMinor,
    required List<double> history,
    required List<InvestmentActivity> activities,
    required DateTime priceUpdatedAt,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return RefreshIndicator(
          onRefresh: _refreshPrices,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 850),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    widget.header,
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Investment Center',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(
                                  color: khanDark,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Refresh live prices',
                          onPressed: _refreshPrices,
                          icon: const Icon(Icons.refresh),
                        ),
                      ],
                    ),
                    Text(
                      'Live prices in EGP · Updated ${_formatTime(priceUpdatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: khanSecondaryDark.withValues(alpha: 0.78),
                      ),
                    ),
                    const SizedBox(height: 18),
                    PortfolioOverview(
                      liraQuantity: portfolio.liraQuantity,
                      paraQuantity: portfolio.paraQuantity,
                      liraValueMinor: liraValueMinor,
                      paraValueMinor: paraValueMinor,
                    ),
                    const SizedBox(height: 28),
                    const HomeSectionHeading(
                      title: 'Choose your unit',
                      subtitle: 'Select LIRA or PARA to purchase.',
                    ),
                    const SizedBox(height: 14),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: LiraCard(
                              unit: lira,
                              onBuyTap: () =>
                                  _openPurchase(context, lira, para),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: ParaCard(
                              unit: para,
                              onBuyTap: () =>
                                  _openPurchase(context, para, lira),
                            ),
                          ),
                        ],
                      )
                    else ...[
                      LiraCard(
                        unit: lira,
                        onBuyTap: () => _openPurchase(context, lira, para),
                      ),
                      const SizedBox(height: 14),
                      ParaCard(
                        unit: para,
                        onBuyTap: () => _openPurchase(context, para, lira),
                      ),
                    ],
                    const SizedBox(height: 28),
                    PerformanceChart(values: history),
                    const SizedBox(height: 26),
                    RecentActivity(activities: activities),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final period = value.hour < 12 ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  void _openPurchase(
    BuildContext context,
    InvestmentUnit initial,
    InvestmentUnit other,
  ) {
    final lira = initial.name == 'LIRA' ? initial : other;
    final para = initial.name == 'PARA' ? initial : other;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvestmentPurchaseScreen(
          initialUnit: initial,
          lira: lira,
          para: para,
        ),
      ),
    );
  }
}
