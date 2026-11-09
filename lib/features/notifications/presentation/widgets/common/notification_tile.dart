import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import '../../../domain/app_notification.dart';
import 'notification_avatar.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });
  final AppNotification notification;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 58,
            child: Text(
              notification.timeLabel,
              textDirection: TextDirection.rtl,
              style: AppTextStyles.smallPrintMedium.copyWith(
                color: Theme.of(context).colorScheme.onSurface
                    .withValues(alpha: .6),
              ),
              textAlign: TextAlign.right,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  notification.title,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 3),
                Text(
                  notification.message,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.notificationBody,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          NotificationAvatar(notification: notification),
        ],
      ),
    ),
  );
}
