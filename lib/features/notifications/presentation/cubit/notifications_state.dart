import '../../domain/app_notification.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.query = '',
    this.loading = false,
    this.refreshing = false,
    this.loadingMore = false,
    this.hasMore = false,
    this.page = 0,
    this.unreadCount,
    this.error,
    this.actionError,
  });

  final List<AppNotification> items;
  final String query;
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final bool hasMore;
  final int page;

  /// Authoritative badge count from `GET /notifications/unread-count`.
  /// Null means unknown; failed refreshes keep the previous value.
  final int? unreadCount;
  final String? error;
  final String? actionError;

  int get badgeCount => unreadCount ?? 0;

  List<AppNotification> get visibleItems {
    final search = query.trim().toLowerCase();
    if (search.isEmpty) return items;
    return items
        .where(
          (item) =>
              '${item.title} ${item.message} ${item.titleFa} ${item.messageFa}'
                  .toLowerCase()
                  .contains(search),
        )
        .toList();
  }

  NotificationsState copyWith({
    List<AppNotification>? items,
    String? query,
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    int? unreadCount,
    String? error,
    String? actionError,
    bool clearError = false,
    bool clearActionError = false,
    bool clearUnreadCount = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      query: query ?? this.query,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      loadingMore: loadingMore ?? this.loadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      unreadCount: clearUnreadCount ? null : (unreadCount ?? this.unreadCount),
      error: clearError ? null : (error ?? this.error),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }
}
