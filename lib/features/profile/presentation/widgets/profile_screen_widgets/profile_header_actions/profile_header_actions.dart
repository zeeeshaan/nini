import 'package:nini/features/profile/presentation/page/profile_settings_screen/profile_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/chat/presentation/pages/chat_inbox_screen.dart';
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

  void _openChatScreen(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => const ChatInboxScreen()));
  }

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
        // Messages button with notification badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            IconButton(
              onPressed: onMessagesPressed ?? () => _openChatScreen(context),
              tooltip: AppStrings.messages,
              icon: const AppIcon(AppIcons.send, size: 27),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
            ),

            if (notificationCount > 0)
              Positioned(
                left: 1,
                top: 5,
                child: Container(
                  width: 16,
                  height: 16,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.notificationBadge,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notificationCount > 9 ? '9+' : notificationCount.toString(),
                    style: AppTextStyles.notificationBadge.copyWith(
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
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
