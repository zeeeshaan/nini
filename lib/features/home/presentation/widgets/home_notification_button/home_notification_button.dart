import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/notification_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class HomeNotificationButton extends StatelessWidget {
  const HomeNotificationButton({
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
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
