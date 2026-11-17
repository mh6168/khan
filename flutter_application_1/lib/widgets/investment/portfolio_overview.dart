import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class PortfolioOverview extends StatelessWidget {
  const PortfolioOverview({
    super.key,
    required this.liraQuantity,
    required this.paraQuantity,
    required this.liraValue,
    required this.paraValue,
  });

  final int liraQuantity;
  final int paraQuantity;
  final double liraValue;
  final double paraValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: khanDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.15),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Your portfolio',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: khanLightGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(Icons.more_horiz_rounded, color: khanLightGold),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            'ESTIMATED SELL-BACK VALUE',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.62),
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'EGP ${(liraValue + paraValue).toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: khanLightGold,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _PortfolioMetric(
                  label: 'LIRA owned',
                  value: '$liraQuantity',
                  icon: Icons.monetization_on_outlined,
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: Colors.white.withValues(alpha: 0.14),
              ),
              Expanded(
                child: _PortfolioMetric(
                  label: 'PARA owned',
                  value: '$paraQuantity',
                  icon: Icons.auto_awesome_outlined,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PortfolioMetric(
            label: 'LIRA value',
            value: 'EGP ${liraValue.toStringAsFixed(2)}',
            icon: Icons.trending_up,
          ),
          const SizedBox(height: 8),
          _PortfolioMetric(
            label: 'PARA value',
            value: 'EGP ${paraValue.toStringAsFixed(2)}',
            icon: Icons.trending_up,
          ),
        ],
      ),
    );
  }
}

class _PortfolioMetric extends StatelessWidget {
  const _PortfolioMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: khanGold),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: Colors.white, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

