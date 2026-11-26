import 'package:hywork/features/profile/presentation/pages/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:hywork/features/notifications/presentation/helpers/open_notifications.dart';
import 'package:hywork/features/notifications/presentation/widgets/common/notifications_button.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/features/chat/presentation/widgets/inbox/chat_inbox_button.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class ProfileHeaderActions extends StatelessWidget {
  const ProfileHeaderActions({
    super.key,
    this.onMessagesPressed,
    this.onMenuPressed,
  });

  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMenuPressed;

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
            unreadCount: state.badgeCount,
            onPressed: () => openNotifications(context),
          ),
        ),
        const SizedBox(width: 8),
        ChatInboxButton(onPressed: onMessagesPressed),

        const SizedBox(width: 8),

        // More options button
        IconButton(
          onPressed: onMenuPressed ?? () => _openSettings(context),
          tooltip: ProfileScreenStrings.moreOptions,
          icon: const AppIcon(AppIcons.menu, size: 30),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 42),
        ),
      ],
    );
  }
}
