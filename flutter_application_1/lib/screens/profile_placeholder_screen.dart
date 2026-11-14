import 'package:flutter/material.dart';

import '../khan_colors.dart';

class ProfilePlaceholderScreen extends StatelessWidget {
  const ProfilePlaceholderScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.details = const {},
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Map<String, String> details;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Khan account'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(22),
              children: [
                Container(
                  padding: const EdgeInsets.all(23),
                  decoration: BoxDecoration(
                    color: khanDark,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: khanGold.withValues(alpha: 0.32)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: const BoxDecoration(
                          color: khanGold,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: khanDark, size: 27),
                      ),
                      const SizedBox(height: 19),
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: khanLightGold,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.75),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: khanGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (var i = 0; i < details.entries.length; i++) ...[
                          _DetailRow(
                            label: details.entries.elementAt(i).key,
                            value: details.entries.elementAt(i).value,
                          ),
                          if (i != details.length - 1)
                            Divider(
                              height: 1,
                              indent: 18,
                              endIndent: 18,
                              color: khanDark.withValues(alpha: 0.07),
                            ),
                        ],
                      ],
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: khanGold.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.hourglass_empty_rounded,
                          color: khanGold,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This section is a preview. No account data or '
                            'activity is available here yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: khanSecondaryDark,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: khanSecondaryDark.withValues(alpha: 0.72)),
            ),
          ),
          const SizedBox(width: 14),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: khanDark, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
