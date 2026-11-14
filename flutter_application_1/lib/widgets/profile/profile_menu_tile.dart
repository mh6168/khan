import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class ProfileMenuTile extends StatelessWidget {
  const ProfileMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.showDivider = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 3,
          ),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: khanLightGold.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: khanDark, size: 21),
          ),
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(color: khanDark, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            subtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: khanSecondaryDark.withValues(alpha: 0.7),
              fontSize: 11,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right_rounded,
            color: khanSecondaryDark,
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 72),
            child: Divider(height: 1, color: khanDark.withValues(alpha: 0.07)),
          ),
      ],
    );
  }
}
