import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/chat/presentation/pages/chat_inbox_screen.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// Shared Home/Profile entry to the existing chat inbox.
class ChatInboxButton extends StatelessWidget {
  const ChatInboxButton({
    super.key,
    this.onPressed,
    this.notificationCount = 1,
  });

  final VoidCallback? onPressed;
  final int notificationCount;

  @override
  Widget build(BuildContext context) => Stack(
    clipBehavior: Clip.none,
    children: [
      IconButton(
        onPressed:
            onPressed ??
            () => Navigator.of(context).push<void>(
              MaterialPageRoute(builder: (_) => const ChatInboxScreen()),
            ),
        tooltip: AppStrings.messages,
        icon: const AppIcon(AppIcons.send, size: 27),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 42, minHeight: 42),
      ),
      if (notificationCount > 0)
        Positioned(
          left: 1,
          top: 5,
          child: IgnorePointer(
            child: Container(
              width: 16,
              height: 16,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: AppColors.notificationBadge,
                shape: BoxShape.circle,
              ),
              child: Text(
                AppStrings.persianDigits(
                  notificationCount > 9 ? '9+' : notificationCount,
                ),
                style: AppTextStyles.notificationBadge.copyWith(
                  color: AppColors.white,
                ),
                textDirection: TextDirection.ltr,
                textAlign: TextAlign.right,
              ),
            ),
          ),
        ),
    ],
  );
}
