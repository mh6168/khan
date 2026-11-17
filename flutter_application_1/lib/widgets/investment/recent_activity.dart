import 'package:flutter/material.dart';

import '../../khan_colors.dart';
import '../../models/investment.dart';

class RecentActivity extends StatelessWidget {
  const RecentActivity({super.key, required this.activities});

  final List<InvestmentActivity> activities;

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
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Completed purchases and buybacks',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.72)),
            ),
          ),
          const SizedBox(height: 10),
          if (activities.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text('No completed investment activity yet'),
            )
          else
            for (var i = 0; i < activities.length; i++) ...[
            _ActivityRow(activity: activities[i]),
            if (i != activities.length - 1)
              Divider(height: 1, color: khanDark.withValues(alpha: 0.07)),
            ],
        ],
      ),
    );
  }
}

String _month(int month) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return months[month - 1];
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final InvestmentActivity activity;

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
            child: Icon(
              activity.type == 'Purchase'
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: khanDark,
              size: 19,
            ),
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
                  activity.date == null
                      ? 'Date unavailable'
                      : '${activity.date!.day} ${_month(activity.date!.month)} ${activity.date!.year}',
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
                '${activity.type == 'Purchase' ? '+' : '-'} ${activity.quantity} ${activity.unit}',
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
