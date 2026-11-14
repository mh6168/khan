import 'package:flutter/material.dart';

import '../../khan_colors.dart';
import '../../models/investment_demo_data.dart';
import 'demo_data_badge.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: khanGold.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent activity',
                  style: Theme.of(context).textTheme.titleLarge
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
              ),
              const DemoDataBadge(compact: true),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Sample entries for display only',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.72)),
            ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < recentInvestmentActivityDemo.length; i++) ...[
            _ActivityRow(activity: recentInvestmentActivityDemo[i]),
            if (i != recentInvestmentActivityDemo.length - 1)
              Divider(height: 1, color: khanDark.withValues(alpha: 0.07)),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final InvestmentActivityDemo activity;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: khanLightGold.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(activity.icon, color: khanDark, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${activity.unit} · ${activity.type}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.date,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                activity.amount,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                activity.status.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: khanSecondaryDark.withValues(alpha: 0.6),
                  fontSize: 8,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
