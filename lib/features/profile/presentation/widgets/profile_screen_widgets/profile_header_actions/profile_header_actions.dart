import 'package:nini/features/profile/presentation/page/profile_settings_screen/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/features/notifications/presentation/helpers/open_notifications.dart';
import 'package:nini/features/notifications/presentation/widgets/notifications_button/notifications_button.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/presentation/widgets/chat_inbox_button/chat_inbox_button.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class ProfileHeaderActions extends StatelessWidget {
  const ProfileHeaderActions({
    super.key,
    this.onMessagesPressed,
    this.onMenuPressed,
    this.notificationCount = 1,
  });

  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMenuPressed;
  final int notificationCount;

  void _openSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const ProfileSettingsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        BlocBuilder<NotificationsCubit, NotificationsState>(
          builder: (context, state) => NotificationsButton(
            unreadCount: state.unreadCount,
            onPressed: () => openNotifications(context),
          ),
        ),
        const SizedBox(width: 8),
        ChatInboxButton(
          onPressed: onMessagesPressed,
          notificationCount: notificationCount,
        ),

        const SizedBox(width: 8),

        // More options button
        IconButton(
          onPressed: onMenuPressed ?? () => _openSettings(context),
          tooltip: AppStrings.moreOptions,
          icon: const AppIcon(AppIcons.more, size: 30),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 42),
        ),
      ],
    );
  }
}
