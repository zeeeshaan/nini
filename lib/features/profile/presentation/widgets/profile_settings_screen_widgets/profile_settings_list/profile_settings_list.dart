import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/localization/profile_settings_strings.dart';
import 'package:nini/features/locations/presentation/pages/locations_screen.dart';
import 'package:nini/features/profile_settings/presentation/pages/accessibility_screen/accessibility_screen.dart';
import 'package:nini/features/profile_settings/presentation/pages/profile_edit_screen.dart';
import 'package:nini/features/wallet/presentation/page/wallet_screen/wallet_screen.dart';

import '../profile_settings_tile/profile_settings_tile.dart';

class ProfileSettingsList extends StatelessWidget {
  const ProfileSettingsList({super.key});
  static const _labels = [
    ProfileSettingsStrings.saved,
    ProfileSettingsStrings.notifications,
    ProfileSettingsStrings.trending,
    ProfileSettingsStrings.insights,
    ProfileSettingsStrings.scheduledContent,
    ProfileSettingsStrings.blocked,
    ProfileSettingsStrings.comments,
    ProfileSettingsStrings.language,
    ProfileSettingsStrings.devicePermissions,
    ProfileSettingsStrings.accessibility,
    ProfileSettingsStrings.posts,
    ProfileSettingsStrings.myMedia,
    ProfileSettingsStrings.tags,
    ProfileSettingsStrings.archive,
  ];
  void _open(BuildContext context, Widget screen) =>
      Navigator.of(context)
          .push(MaterialPageRoute<void>(builder: (_) => screen));
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.only(top: 12, bottom: 24),
    children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(22, 4, 22, 12),
        child: Text(
          ProfileSettingsStrings.general,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: AppTextStyles.sectionTitle,
        ),
      ),
      ProfileSettingsTile(
        label: ProfileSettingsStrings.profile,
        onTap: () => _open(context, const ProfileEditScreen()),
      ),
      ProfileSettingsTile(
        label: ProfileSettingsStrings.locations,
        onTap: () => _open(context, const LocationsScreen()),
      ),
      ProfileSettingsTile(
        label: ProfileSettingsStrings.wallet,
        onTap: () => _open(context, const WalletScreen()),
      ),
      for (final label in _labels)
        ProfileSettingsTile(
          label: label,
          onTap: label == ProfileSettingsStrings.accessibility
              ? () => _open(context, const AccessibilityScreen())
              : null,
        ),
    ],
  );
}
