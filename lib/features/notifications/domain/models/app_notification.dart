/// UI data for one notification. Kept separate from the widgets and sample list.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeLabel,
    this.imageUrl,
    this.unreadCount = 0,
  });
  final String id, title, message, timeLabel;
  final String? imageUrl;
  final int unreadCount;

  AppNotification markRead() => AppNotification(
    id: id,
    title: title,
    message: message,
    timeLabel: timeLabel,
    imageUrl: imageUrl,
  );
}
