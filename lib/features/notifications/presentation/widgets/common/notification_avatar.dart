import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_assets/app_assets.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';

import '../../../domain/app_notification.dart';

class NotificationAvatar extends StatelessWidget {
  const NotificationAvatar({super.key, required this.notification});
  final AppNotification notification;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 54,
      height: 58,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 50,
              height: 50,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: notification.imageUrl == null
                    ? AppColors.black
                    : colors.surface,
                border: Border.all(
                  color: notification.imageUrl == null
                      ? AppColors.black
                      : colors.outline,
                ),
              ),
              child: ClipOval(
                child: notification.imageUrl == null
                    ? const AppIcon(
                        AppAssets.hyworkLogo,
                        color: AppColors.white,
                        size: 31,
                      )
                    : Image.network(
                        notification.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Icon(
                          Icons.fastfood_outlined,
                          color: colors.onSurface,
                          size: 26,
                        ),
                      ),
              ),
            ),
          ),
          if (notification.unreadCount > 0)
            Positioned(
              top: 0,
              left: -2,
              child: Container(
                constraints: const BoxConstraints(minWidth: 21, minHeight: 21),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: const BoxDecoration(
                  color: AppColors.notificationBadge,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  AppStrings.persianDigits(notification.unreadCount),
                  textAlign: TextAlign.center,
                  style: AppTextStyles.helperBold.copyWith(
                    color: AppColors.white,
                  ),
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
