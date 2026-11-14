import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class DemoDataBadge extends StatelessWidget {
  const DemoDataBadge({
    super.key,
    this.compact = false,
    this.darkSurface = false,
  });

  final bool compact;
  final bool darkSurface;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: darkSurface
            ? khanGold.withValues(alpha: 0.13)
            : khanLightGold.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: khanGold.withValues(alpha: 0.4)),
      ),
      child: Text(
        'DEMO DATA',
        style: TextStyle(
          color: darkSurface ? khanLightGold : khanDark,
          fontSize: compact ? 8 : 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
