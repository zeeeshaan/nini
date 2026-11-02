import 'package:nini/core/localization/notification_strings.dart';

import '../domain/models/app_notification.dart';

/// UI preview data; replace this list when the notification API is connected.
final sampleNotifications = <AppNotification>[
  const AppNotification(
    id: 'order-1',
    title: NotificationStrings.brand,
    message: NotificationStrings.newOrder,
    timeLabel: NotificationStrings.now,
    unreadCount: 1,
  ),
  for (var index = 0; index < 6; index++)
    AppNotification(
      id: 'sale-$index',
      title: NotificationStrings.saleTitle,
      message: NotificationStrings.saleMessage,
      timeLabel: NotificationStrings.minuteAgo,
      imageUrl: 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=160&h=160&fit=crop',
      unreadCount: index == 0 ? 0 : 2,
    ),
];
