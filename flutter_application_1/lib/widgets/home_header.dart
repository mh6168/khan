import 'package:flutter/material.dart';

import '../khan_colors.dart';
import 'khan_logo.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    required this.customerName,
    required this.onNotificationsTap,
    required this.onLogoutTap,
  });

  final String? customerName;
  final VoidCallback onNotificationsTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 18),
      decoration: BoxDecoration(
        color: khanDark,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.12),
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
              const KhanLogo(width: 96, height: 36),
              const Spacer(),
              _HeaderAction(
                tooltip: 'Notifications',
                icon: Icons.notifications_none_rounded,
                onPressed: onNotificationsTap,
              ),
              _HeaderAction(
                tooltip: 'Log out',
                icon: Icons.logout_rounded,
                onPressed: onLogoutTap,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'A little gold, a lot of meaning.',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: khanLightGold,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            customerName == null
                ? 'Welcome to Khan. Find something timeless.'
                : 'Welcome back, $customerName. Find something timeless.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        foregroundColor: khanGold,
      ),
      icon: Icon(icon, size: 21),
    );
  }
}
