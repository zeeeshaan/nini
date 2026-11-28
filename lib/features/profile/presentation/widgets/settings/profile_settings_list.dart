import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/locations/presentation/pages/locations_screen.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/notifications/presentation/helpers/open_notifications.dart';
import 'package:hywork/features/profile_settings/presentation/pages/accessibility_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/profile_edit_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/trending_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/insights_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/scheduled_content_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/blocked_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/comments_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/language_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/device_permissions_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/posts_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/my_media_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/tags_keywords_screen.dart';
import 'package:hywork/features/profile_settings/presentation/pages/archive_screen.dart';
import 'package:hywork/features/wallet/presentation/pages/wallet_screen.dart';
import 'package:hywork/features/saved_posts/presentation/pages/saved_posts_screen.dart';
import 'package:hywork/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:hywork/features/team/presentation/pages/my_team.dart';

import 'profile_settings_tile.dart';
import 'profile_logout_dialog.dart';

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
      for (final label in _labels)
        ProfileSettingsTile(
          label: label,
          onTap: switch (label) {
            ProfileSettingsStrings.notifications => () => openNotifications(
              context,
            ),
            ProfileSettingsStrings.saved => () {
              context.read<SavedPostsCubit>().refreshOnOpen();
              _open(context, const SavedPostsScreen());
            },
            ProfileSettingsStrings.accessibility => () => _open(
              context,
              const AccessibilityScreen(),
            ),
            ProfileSettingsStrings.trending => () => _open(
              context,
              const TrendingScreen(),
            ),
            ProfileSettingsStrings.insights => () => _open(
              context,
              const InsightsScreen(),
            ),
            ProfileSettingsStrings.scheduledContent => () => _open(
              context,
              const ScheduledContentScreen(),
            ),
            ProfileSettingsStrings.blocked => () => _open(
              context,
              const BlockedScreen(),
            ),
            ProfileSettingsStrings.comments => () => _open(
              context,
              const CommentsScreen(),
            ),
            ProfileSettingsStrings.language => () => _open(
              context,
              const LanguageScreen(),
            ),
            ProfileSettingsStrings.devicePermissions => () => _open(
              context,
              const DevicePermissionsScreen(),
            ),
            ProfileSettingsStrings.posts => () => _open(
              context,
              const PostsScreen(),
            ),
            ProfileSettingsStrings.myMedia => () => _open(
              context,
              const MyMediaScreen(),
            ),
            ProfileSettingsStrings.tags => () => _open(
              context,
              const TagsKeywordsScreen(),
            ),
            ProfileSettingsStrings.archive => () => _open(
              context,
              const ArchiveScreen(),
            ),
            _ => null,
          },
        ),
      ProfileSettingsTile(
        label: ProfileSettingsStrings.logout,
        onTap: () {
          final session = context.read<SessionCubit>();
          showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => BlocProvider.value(
              value: session,
              child: const ProfileLogoutDialog(),
            ),
          );
        },
      ),
    ],
  );
}
