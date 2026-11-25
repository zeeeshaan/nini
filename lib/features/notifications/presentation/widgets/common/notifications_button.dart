import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/notification_strings.dart';
import 'package:nini/core/theme/app_colors/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class NotificationsButton extends StatelessWidget {
  const NotificationsButton({
    super.key,
    required this.unreadCount,
    required this.onPressed,
  });
  final int unreadCount;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 48,
    height: 48,
    child: Stack(
      children: [
        IconButton(
          tooltip: NotificationStrings.title,
          onPressed: onPressed,
          icon: const AppIcon(AppIcons.notifications, size: 26),
        ),
        if (unreadCount > 0)
          Positioned(
            top: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.notificationBadge,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  AppStrings.persianDigits(
                    unreadCount > 99 ? '99+' : unreadCount,
                  ),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.smallPrintBold.copyWith(
                    color: AppColors.white,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
