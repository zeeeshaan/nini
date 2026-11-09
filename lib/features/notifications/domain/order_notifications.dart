import 'package:nini/core/localization/notification_strings.dart';
import 'package:nini/core/localization/provider_order_strings.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/cart/domain/models/cart_order_status.dart';
import 'package:nini/features/cart/domain/policies/order_access.dart';

import 'app_notification.dart';

/// Keep placement and completion as distinct entries instead of replacing one.
List<AppNotification> orderNotifications(
  List<CartOrder> orders,
  String userId,
) {
  final result = <AppNotification>[];
  for (final order in orders) {
    final provider = OrderAccess.isProvider(order, userId);
    if (!provider && !OrderAccess.isBuyer(order, userId)) continue;
    final status = order.status;
    if (status == null) continue;
    final events = <CartOrderStatus, DateTime>{
      if (order.paidAt != null) CartOrderStatus.paid: order.paidAt!,
      ...order.timeline,
    };
    events.putIfAbsent(status, () => order.createdAt);
    final readAt = provider ? order.providerReadAt : order.customerReadAt;
    for (final event in events.entries) {
      final message = provider
          ? switch (event.key) {
              CartOrderStatus.paid ||
              CartOrderStatus.pendingApproval => NotificationStrings.newOrder,
              CartOrderStatus.disputed => ProviderOrderStrings.buyerDispute,
              CartOrderStatus.completed =>
                ProviderOrderStrings.buyerCompletedNotice,
              _ => ProviderOrderStrings.statusNotice(event.key.label),
            }
          : switch (event.key) {
              CartOrderStatus.paid => ProviderOrderStrings.placedNotice,
              CartOrderStatus.accepted => ProviderOrderStrings.acceptedNotice,
              CartOrderStatus.canceled => ProviderOrderStrings.canceledNotice,
              CartOrderStatus.completed => ProviderOrderStrings.completedNotice,
              _ => ProviderOrderStrings.statusNotice(event.key.label),
            };
      result.add(
        AppNotification(
          id: 'order-${order.id}-${event.key.name}',
          orderId: order.id,
          asProvider: provider,
          title: NotificationStrings.brand,
          message: message,
          createdAt: event.value,
          timeLabel: _relativeTime(event.value),
          unreadCount: readAt == null || readAt.isBefore(event.value) ? 1 : 0,
        ),
      );
    }
  }
  result.sort((a, b) => b.createdAt!.compareTo(a.createdAt!));
  return List.unmodifiable(result);
}

String _relativeTime(DateTime date) {
  final elapsed = DateTime.now().difference(date);
  if (elapsed.inMinutes < 1) return NotificationStrings.now;
  if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
  if (elapsed.inDays < 1) return '${elapsed.inHours}h ago';
  return '${elapsed.inDays}d ago';
}
