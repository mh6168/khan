import 'package:flutter/material.dart';

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

  @override
  void initState() {
    super.initState();
    _service.refreshPrices().catchError((_) {});
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: _service.watchPrices(),
      builder: (context, priceSnapshot) {
        final prices = priceSnapshot.data ?? const {};
        final liraSpot = _intValue(prices['liraSpotMinor']);
        final paraSpot = _intValue(prices['paraSpotMinor']);
        final liraPurchase = _intValue(prices['liraSellingMinor']);
        final paraPurchase = _intValue(prices['paraSellingMinor']);
        final liraBuyback = _intValue(prices['liraBuybackMinor']);
        final paraBuyback = _intValue(prices['paraBuybackMinor']);

        return StreamBuilder<Map<String, int>>(
          stream: _service.watchInventory(),
          builder: (context, inventorySnapshot) {
            final inventory =
                inventorySnapshot.data ?? const {'lira': 0, 'para': 0};
            final lira = InvestmentUnit(
              name: 'LIRA',
              description: 'Digital gold investment unit',
              definition: '1 LIRA represents 0.01 grams of 24-karat gold.',
              spotMinor: liraSpot,
              purchaseMinor: liraPurchase,
              buybackMinor: liraBuyback,
              availableQuantity: inventory['lira'] ?? 0,
              icon: Icons.monetization_on_outlined,
              accent: const Color(0xFFB88C31),
            );
            final para = InvestmentUnit(
              name: 'PARA',
              description: 'Digital silver investment unit',
              definition: '1 PARA represents 1 gram of 925 silver.',
              spotMinor: paraSpot,
              purchaseMinor: paraPurchase,
              buybackMinor: paraBuyback,
              availableQuantity: inventory['para'] ?? 0,
              icon: Icons.auto_awesome_outlined,
              accent: const Color(0xFF658087),
            );

            return StreamBuilder<InvestmentPortfolio>(
              stream: _service.watchPortfolio(),
              builder: (context, portfolioSnapshot) {
                final portfolio =
                    portfolioSnapshot.data ?? const InvestmentPortfolio();
                final liraValue =
                    portfolio.liraQuantity * lira.buybackPrice;
                final paraValue =
                    portfolio.paraQuantity * para.buybackPrice;

                return StreamBuilder<List<double>>(
                  stream: _service.watchPriceHistory(),
                  builder: (context, historySnapshot) {
                    final history = historySnapshot.data ?? const [];

                    return StreamBuilder<List<InvestmentActivity>>(
                      stream: _service.watchActivity(),
                      builder: (context, activitySnapshot) {
                        final activities =
                            activitySnapshot.data ?? const [];
                        return _buildScreen(
                          context,
                          lira,
                          para,
                          portfolio,
                          liraValue,
                          paraValue,
                          history,
                          activities,
                        );
                      },
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

  Widget _buildScreen(
    BuildContext context,
    InvestmentUnit lira,
    InvestmentUnit para,
    InvestmentPortfolio portfolio,
    double liraValue,
    double paraValue,
    List<double> history,
    List<InvestmentActivity> activities,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 700;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  widget.header,
                  const SizedBox(height: 24),
                  Text(
                    'Investment Center',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: khanDark,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Invest in precious metals.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: khanSecondaryDark.withValues(alpha: 0.78),
                        ),
                  ),
                  const SizedBox(height: 18),
                  PortfolioOverview(
                    liraQuantity: portfolio.liraQuantity,
                    paraQuantity: portfolio.paraQuantity,
                    liraValue: liraValue,
                    paraValue: paraValue,
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
                            onBuyTap: () => _openPurchase(context, lira, para),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ParaCard(
                            unit: para,
                            onBuyTap: () => _openPurchase(context, para, lira),
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
        );
      },
    );
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

  int _intValue(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
