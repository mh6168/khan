import 'package:flutter/material.dart';

import '../../khan_colors.dart';
import '../../models/investment.dart';

class InvestmentUnitCard extends StatelessWidget {
  const InvestmentUnitCard({
    super.key,
    required this.unit,
    required this.onBuyTap,
  });

  final InvestmentUnit unit;
  final VoidCallback onBuyTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(19),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            khanDark,
            khanSecondaryDark,
            unit.accent.withValues(alpha: 0.8),
          ],
          stops: const [0, 0.62, 1],
        ),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: khanGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: khanGold.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: khanGold.withValues(alpha: 0.38)),
                ),
                child: Icon(unit.icon, color: khanGold, size: 25),
              ),
              const Spacer(),
              if (unit.availableQuantity == 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'OUT OF STOCK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 17),
          Text(
            unit.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: khanLightGold,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            unit.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          if (unit.definition != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: khanGold,
                    size: 17,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      unit.definition!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: khanLightGold,
                        fontSize: 11,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BUY PRICE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.58),
                        fontSize: 8,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      unit.purchaseLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: khanLightGold,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_rounded,
                color: khanGold,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Spot price: ${unit.spotLabel}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.76)),
          ),
          const SizedBox(height: 4),
          Text(
            'Sell-back price: ${unit.buybackLabel}',
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.76)),
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: unit.availableQuantity > 0 && unit.purchaseMinor > 0
                  ? onBuyTap
                  : null,
              style: FilledButton.styleFrom(
                backgroundColor: khanGold,
                foregroundColor: khanDark,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Buy ${unit.name}',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
