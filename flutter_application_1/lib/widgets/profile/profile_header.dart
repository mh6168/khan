import 'package:flutter/material.dart';

import '../../khan_colors.dart';

class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
  });

  final String? name;
  final String? email;
  final String? phone;

  @override
  Widget build(BuildContext context) {
    final displayName = _valueOrFallback(name, 'Khan customer');
    final initials = _initials(displayName);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [khanDark, khanSecondaryDark],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: khanGold.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: khanDark.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 9),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: khanGold, width: 1.5),
            ),
            child: CircleAvatar(
              radius: 34,
              backgroundColor: khanLightGold,
              child: Text(
                initials,
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: khanLightGold,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (_hasValue(email)) ...[
                  const SizedBox(height: 5),
                  _ProfileContact(
                    icon: Icons.email_outlined,
                    value: email!.trim(),
                  ),
                ],
                if (_hasValue(phone)) ...[
                  const SizedBox(height: 4),
                  _ProfileContact(
                    icon: Icons.phone_outlined,
                    value: phone!.trim(),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;

  String _valueOrFallback(String? value, String fallback) =>
      _hasValue(value) ? value!.trim() : fallback;

  String _initials(String value) {
    final parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .toList();
    return parts.map((part) => part[0].toUpperCase()).join();
  }
}

class _ProfileContact extends StatelessWidget {
  const _ProfileContact({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 15, color: khanGold),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Colors.white.withValues(alpha: 0.76)),
          ),
        ),
      ],
    );
  }
}
