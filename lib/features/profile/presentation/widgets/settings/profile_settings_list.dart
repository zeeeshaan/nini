import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/profile_settings_strings.dart';
import 'package:nini/features/locations/presentation/pages/locations_screen.dart';
import 'package:nini/features/profile_settings/presentation/pages/accessibility_screen.dart';
import 'package:nini/features/profile_settings/presentation/pages/profile_edit_screen.dart';
import 'package:nini/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:nini/features/saved_posts/presentation/pages/saved_posts_screen.dart';
import 'package:nini/features/team/presentation/pages/my_team.dart';
import 'package:nini/shimmer%20previe.dart';

import 'profile_settings_tile.dart';

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
      ProfileSettingsTile(
        label: ProfileSettingsStrings.myTeam,
        trailingIcon: AppIcons.team,
        onTap: () => _open(context, const MyTeamsScreen()),
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
      if (kDebugMode)
        ProfileSettingsTile(
          label: 'Shimmer Preview',
          icon: AppIcons.playCircle,
          onTap: () => _open(context, const ShimmerPreviewScreen()),
        ),
      for (final label in _labels)
        ProfileSettingsTile(
          label: label,
          onTap: switch (label) {
            ProfileSettingsStrings.saved => () => _open(
              context,
              const SavedPostsScreen(),
            ),
            ProfileSettingsStrings.accessibility => () => _open(
              context,
              const AccessibilityScreen(),
            ),
            _ => null,
          },
        ),
    ],
  );
}
