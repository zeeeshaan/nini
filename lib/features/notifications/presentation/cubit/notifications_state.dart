import '../../domain/app_notification.dart';

class NotificationsState {
  const NotificationsState({required this.items, this.query = ''});
  final List<AppNotification> items;
  final String query;
  int get unreadCount =>
      items.fold(0, (count, item) => count + item.unreadCount);
  List<AppNotification> get visibleItems {
    final search = query.trim().toLowerCase();
    return items
        .where(
          (item) =>
              '${item.title} ${item.message}'.toLowerCase().contains(search),
        )
        .toList();
  }
}
