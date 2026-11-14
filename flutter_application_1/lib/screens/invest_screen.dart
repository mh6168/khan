import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../models/investment_demo_data.dart';
import '../widgets/home_sections.dart';
import '../widgets/investment/demo_data_badge.dart';
import '../widgets/investment/lira_card.dart';
import '../widgets/investment/para_card.dart';
import '../widgets/investment/performance_chart.dart';
import '../widgets/investment/portfolio_overview.dart';
import '../widgets/investment/recent_activity.dart';
import 'investment_purchase_screen.dart';

class InvestScreen extends StatelessWidget {
  const InvestScreen({super.key, required this.header});

  final Widget header;

  @override
  Widget build(BuildContext context) {
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
                  header,
                  const SizedBox(height: 24),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Investment Center',
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: khanDark,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Explore new ways to invest in precious metals.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: khanSecondaryDark.withValues(
                                      alpha: 0.78,
                                    ),
                                    height: 1.4,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      const DemoDataBadge(),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const PortfolioOverview(),
                  const SizedBox(height: 28),
                  const HomeSectionHeading(
                    title: 'Choose your unit',
                    subtitle: 'A new way to explore precious metals.',
                  ),
                  const SizedBox(height: 14),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LiraCard(
                            onBuyTap: () => _openPurchase(context, liraDemo),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: ParaCard(
                            onBuyTap: () => _openPurchase(context, paraDemo),
                          ),
                        ),
                      ],
                    )
                  else ...[
                    LiraCard(onBuyTap: () => _openPurchase(context, liraDemo)),
                    const SizedBox(height: 14),
                    ParaCard(onBuyTap: () => _openPurchase(context, paraDemo)),
                  ],
                  const SizedBox(height: 28),
                  const PerformanceChart(),
                  const SizedBox(height: 26),
                  const RecentActivity(),
                  const SizedBox(height: 16),
                  Text(
                    'All balances, prices, performance and activity on this '
                    'screen are illustrative demonstration data.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: khanSecondaryDark.withValues(alpha: 0.68),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _openPurchase(BuildContext context, InvestmentUnitDemo unit) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => InvestmentPurchaseScreen(initialUnit: unit),
      ),
    );
  }
}
