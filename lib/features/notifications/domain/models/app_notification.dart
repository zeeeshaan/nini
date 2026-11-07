/// Notification display data with an optional saved-order destination.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.imageUrl,
    this.unreadCount = 0,
    this.orderId,
    this.asProvider = false,
    this.createdAt,
  });
  final String id, title, message, timeLabel;
  final String? imageUrl;
  final int unreadCount;
  final String? orderId;
  final bool asProvider;
  final DateTime? createdAt;

  AppNotification markRead() => AppNotification(
    id: id,
    title: title,
    message: message,
    timeLabel: timeLabel,
    imageUrl: imageUrl,
    orderId: orderId,
    asProvider: asProvider,
    createdAt: createdAt,
  );
}
