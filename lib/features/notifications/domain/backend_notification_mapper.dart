import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';

/// Maps Swagger notification records into existing inbox display models.
AppNotification appNotificationFromBackend(BackendNotification notification) {
  return AppNotification(
    id: notification.id,
    title: notification.title,
    message: notification.body,
    titleFa: notification.titleFa,
    messageFa: notification.bodyFa,
    createdAt: notification.createdAt,
    timeLabel: relativeNotificationTime(notification.createdAt),
    unreadCount: notification.isRead ? 0 : 1,
    targetType: notification.target?.type,
    targetId: notification.target?.id,
  );
}

String relativeNotificationTime(DateTime date, {DateTime? now}) {
  final elapsed = (now ?? DateTime.now()).difference(date);
  if (elapsed.inMinutes < 1) return NotificationStrings.now;
  if (elapsed.inHours < 1) {
    return NotificationStrings.minutesAgo(elapsed.inMinutes);
  }
  if (elapsed.inDays < 1) return NotificationStrings.hoursAgo(elapsed.inHours);
  return NotificationStrings.daysAgo(elapsed.inDays);
}
