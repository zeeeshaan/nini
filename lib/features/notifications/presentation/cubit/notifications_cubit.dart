import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/sample_notifications.dart';
import '../../domain/models/app_notification.dart';
import 'notifications_state.dart';

export 'notifications_state.dart';

/// Search and read state for this UI preview; no storage or network layer yet.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit()
    : super(NotificationsState(items: List.unmodifiable(sampleNotifications)));
  void search(String query) =>
      emit(NotificationsState(items: state.items, query: query));
  void markRead(String id) => emit(
    NotificationsState(
      query: state.query,
      items: List<AppNotification>.unmodifiable([
        for (final item in state.items)
          if (item.id == id) item.markRead() else item,
      ]),
    ),
  );
}
