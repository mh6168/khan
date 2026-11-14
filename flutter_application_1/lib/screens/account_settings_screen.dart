import 'package:flutter/material.dart';

import '../khan_colors.dart';
import '../widgets/profile/profile_menu_section.dart';
import '../widgets/profile/profile_menu_tile.dart';
import 'profile_placeholder_screen.dart';

class AccountSettingsScreen extends StatefulWidget {
  const AccountSettingsScreen({super.key});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  bool _orderUpdates = true;
  bool _productNews = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: khanBackground,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: khanDark,
        foregroundColor: khanLightGold,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              children: [
                Text(
                  'Your preferences',
                  style: Theme.of(context).textTheme.headlineSmall
                      ?.copyWith(color: khanDark, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  'A few thoughtful touches for your Khan experience.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.76),
                  ),
                ),
                const SizedBox(height: 22),
                const _SettingsLabel('NOTIFICATIONS'),
                ProfileMenuSection(
                  children: [
                    SwitchListTile(
                      value: _orderUpdates,
                      onChanged: (value) =>
                          setState(() => _orderUpdates = value),
                      activeTrackColor: khanGold,
                      secondary: const Icon(
                        Icons.local_shipping_outlined,
                        color: khanDark,
                      ),
                      title: const Text('Order updates'),
                      subtitle: const Text('News about your orders'),
                    ),
                    Divider(
                      height: 1,
                      indent: 18,
                      endIndent: 18,
                      color: khanDark.withValues(alpha: 0.07),
                    ),
                    SwitchListTile(
                      value: _productNews,
                      onChanged: (value) =>
                          setState(() => _productNews = value),
                      activeTrackColor: khanGold,
                      secondary: const Icon(
                        Icons.auto_awesome_outlined,
                        color: khanDark,
                      ),
                      title: const Text('New arrivals and stories'),
                      subtitle: const Text('Occasional Khan highlights'),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                const _SettingsLabel('ACCOUNT'),
                ProfileMenuSection(
                  children: [
                    ProfileMenuTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy',
                      subtitle: 'Your privacy preferences',
                      onTap: () => _openPreview(
                        context,
                        title: 'Privacy',
                        subtitle: 'Your privacy preferences will appear here.',
                        icon: Icons.privacy_tip_outlined,
                      ),
                    ),
                    ProfileMenuTile(
                      icon: Icons.language_rounded,
                      title: 'Language',
                      subtitle: 'English',
                      showDivider: false,
                      onTap: () => _openPreview(
                        context,
                        title: 'Language',
                        subtitle: 'Language options will appear here.',
                        icon: Icons.language_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'These preview preferences are kept on this screen only.',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: khanSecondaryDark.withValues(alpha: 0.68),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openPreview(
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

class _SettingsLabel extends StatelessWidget {
  const _SettingsLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 9),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: khanSecondaryDark.withValues(alpha: 0.7),
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
