import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../widgets/profile/profile_header.dart';
import '../widgets/profile/profile_menu_section.dart';
import '../widgets/profile/profile_menu_tile.dart';
import 'profile_placeholder_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.header,
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.profileLoadFailed,
    required this.onLogout,
    required this.onFavoritesTap,
    required this.onAccountSettingsTap,
  });

  final Widget header;
  final String? customerName;
  final String? customerEmail;
  final String? customerPhone;
  final bool profileLoadFailed;
  final VoidCallback onLogout;
  final VoidCallback onFavoritesTap;
  final VoidCallback onAccountSettingsTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              const SizedBox(height: 22),
              Text(
                'My Account',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(color: khanDark, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 5),
              Text(
                'Your Khan, your way.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: khanSecondaryDark.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 17),
              ProfileHeader(
                name: customerName,
                email: customerEmail,
                phone: customerPhone,
              ),
              if (profileLoadFailed) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: khanDark),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Some profile details could not be loaded. '
                          'Your sign-in information is still available.',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              const _MenuCaption('YOUR ACCOUNT'),
              ProfileMenuSection(
                children: [
                  ProfileMenuTile(
                    icon: Icons.badge_outlined,
                    title: 'Personal Information',
                    subtitle: 'Your account details',
                    onTap: () => _openPersonalInformation(context),
                  ),
                  ProfileMenuTile(
                    icon: Icons.receipt_long_outlined,
                    title: 'My Orders',
                    subtitle: 'Order history and updates',
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'My Orders',
                      subtitle: 'Your order history will live here.',
                      icon: Icons.receipt_long_outlined,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.trending_up_rounded,
                    title: 'My Investments',
                    subtitle: 'Your LIRA and PARA activity',
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'My Investments',
                      subtitle: 'Your investment activity will appear here.',
                      icon: Icons.trending_up_rounded,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'My Favorites',
                    subtitle: 'The jewelry you have saved',
                    showDivider: false,
                    onTap: onFavoritesTap,
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const _MenuCaption('PREFERENCES & SUPPORT'),
              ProfileMenuSection(
                children: [
                  ProfileMenuTile(
                    icon: Icons.settings_outlined,
                    title: 'Account Settings',
                    subtitle: 'Manage your preferences',
                    onTap: onAccountSettingsTap,
                  ),
                  ProfileMenuTile(
                    icon: Icons.support_agent_rounded,
                    title: 'Help and Support',
                    subtitle: 'We are here to help',
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'Help and Support',
                      subtitle: 'Support resources will appear here.',
                      icon: Icons.support_agent_rounded,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'About Khan',
                    subtitle: 'The story behind the craft',
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'About Khan',
                      subtitle: 'A marketplace for meaningful treasures.',
                      icon: Icons.auto_awesome_outlined,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.shield_outlined,
                    title: 'Privacy Policy',
                    subtitle: 'How your information is treated',
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'Privacy Policy',
                      subtitle: 'Privacy information will appear here.',
                      icon: Icons.shield_outlined,
                    ),
                  ),
                  ProfileMenuTile(
                    icon: Icons.description_outlined,
                    title: 'Terms and Conditions',
                    subtitle: 'The details of using Khan',
                    showDivider: false,
                    onTap: () => _openPlaceholder(
                      context,
                      title: 'Terms and Conditions',
                      subtitle: 'Terms and conditions will appear here.',
                      icon: Icons.description_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 54,
                child: OutlinedButton.icon(
                  onPressed: onLogout,
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out of Khan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: khanDark,
                    backgroundColor: Colors.white,
                    side: BorderSide(color: khanGold.withValues(alpha: 0.55)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'KHAN  ·  MADE TO BE TREASURED',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: khanSecondaryDark.withValues(alpha: 0.5),
                  letterSpacing: 1.1,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openPersonalInformation(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePlaceholderScreen(
          title: 'Personal Information',
          subtitle: 'Your details associated with your Khan account.',
          icon: Icons.badge_outlined,
          details: {
            'Full name': customerName ?? 'Not provided',
            'Email address': customerEmail ?? 'Not provided',
            'Phone number': customerPhone ?? 'Not provided',
          },
        ),
      ),
    );
  }

  void _openPlaceholder(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ProfilePlaceholderScreen(
          title: title,
          subtitle: subtitle,
          icon: icon,
        ),
      ),
    );
  }
}

class _MenuCaption extends StatelessWidget {
  const _MenuCaption(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: khanSecondaryDark.withValues(alpha: 0.68),
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
