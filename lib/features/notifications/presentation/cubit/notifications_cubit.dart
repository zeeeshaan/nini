import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification_mapper.dart';

import 'notifications_state.dart';
export 'notifications_state.dart';

/// Account-scoped inbox backed by `ApiNotificationsRepository`.
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(this._repository, {required this.isCurrentAccount})
    : super(const NotificationsState(loading: true)) {
    if (isCurrentAccount()) {
      unawaited(load());
      unawaited(refreshUnreadCount());
    } else {
      emit(const NotificationsState());
    }
  }

  final ApiNotificationsRepository _repository;
  final bool Function() isCurrentAccount;

  static const _pageSize = 20;

  int _listRevision = 0;
  int _unreadRevision = 0;
  Future<void>? _loadMoreInFlight;
  Future<void>? _unreadInFlight;
  final Set<String> _markingIds = {};
  bool _markingAll = false;

  void search(String query) {
    if (isClosed) return;
    emit(state.copyWith(query: query));
  }

  Future<void> load() => _runLoad(replace: true, keepExisting: false);

  Future<void> refresh() => _runLoad(replace: true, keepExisting: true);

  Future<void> loadMore() {
    if (state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore ||
        !isCurrentAccount()) {
      return Future.value();
    }
    return _loadMoreInFlight ??= _runLoad(
      replace: false,
      keepExisting: true,
    ).whenComplete(() => _loadMoreInFlight = null);
  }

  Future<void> retry() => load();

  Future<void> _runLoad({
    required bool replace,
    required bool keepExisting,
  }) async {
    if (isClosed) return;
    if (!isCurrentAccount()) {
      emit(const NotificationsState());
      return;
    }

    final revision = replace ? ++_listRevision : _listRevision;
    final page = replace ? 1 : state.page + 1;
    emit(
      state.copyWith(
        loading: replace && !keepExisting,
        refreshing: replace && keepExisting,
        loadingMore: !replace,
        clearError: true,
        clearActionError: true,
        items: replace && !keepExisting ? const [] : null,
        page: replace && !keepExisting ? 0 : null,
        hasMore: replace && !keepExisting ? false : null,
      ),
    );

    try {
      final result = await _repository.list(page: page, limit: _pageSize);
      if (isClosed || revision != _listRevision || !isCurrentAccount()) return;

      final mapped = [
        for (final item in result.items) appNotificationFromBackend(item),
      ];
      final merged = <AppNotification>[];
      final seen = <String>{};
      if (!replace) {
        for (final item in state.items) {
          if (seen.add(item.id)) merged.add(item);
        }
      }
      for (final item in mapped) {
        if (seen.add(item.id)) merged.add(item);
      }

      emit(
        state.copyWith(
          items: List.unmodifiable(merged),
          loading: false,
          refreshing: false,
          loadingMore: false,
          page: result.page,
          hasMore: result.page * result.limit < result.total,
          // Dedicated unread-count API remains authoritative when already known.
          unreadCount: state.unreadCount ?? result.unreadCount,
          clearError: true,
        ),
      );
      if (replace) unawaited(refreshUnreadCount());
    } catch (_) {
      if (isClosed || revision != _listRevision) return;
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          loadingMore: false,
          error: NotificationStrings.loadFailed,
        ),
      );
    }
  }

  Future<void> refreshUnreadCount() {
    if (!isCurrentAccount()) return Future.value();
    if (_unreadInFlight != null) return _unreadInFlight!;
    final future = _runUnreadCount();
    _unreadInFlight = future.whenComplete(() {
      if (identical(_unreadInFlight, future)) _unreadInFlight = null;
    });
    return _unreadInFlight!;
  }

  Future<void> _runUnreadCount() async {
    if (isClosed || !isCurrentAccount()) return;
    final revision = ++_unreadRevision;
    try {
      final count = await _repository.unreadCount();
      if (isClosed || revision != _unreadRevision || !isCurrentAccount()) {
        return;
      }
      emit(state.copyWith(unreadCount: count));
    } catch (_) {
      // Keep the previous badge value; never fabricate zero on failure.
      if (isClosed || revision != _unreadRevision) return;
    }
  }

  /// Marks one notification read. Already-read ids succeed without a request.
  Future<bool> markRead(String id) async {
    if (isClosed || !isCurrentAccount()) return false;
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return false;
    final item = state.items[index];
    if (item.unreadCount == 0) return true;
    if (!_markingIds.add(id)) return false;

    emit(state.copyWith(clearActionError: true));
    try {
      final result = await _repository.markRead(ids: [id]);
      if (isClosed || !isCurrentAccount()) return false;
      final items = [...state.items];
      items[index] = item.markRead();
      emit(
        state.copyWith(
          items: List.unmodifiable(items),
          unreadCount: result.unreadCount,
          clearActionError: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(actionError: _mutationError(error)));
      return false;
    } finally {
      _markingIds.remove(id);
    }
  }

  /// Mark-all API support. No inbox control currently exposes this action.
  Future<bool> markAllRead() async {
    if (isClosed || !isCurrentAccount() || _markingAll) return false;
    _markingAll = true;
    emit(state.copyWith(clearActionError: true));
    try {
      final result = await _repository.markRead(markAll: true);
      if (isClosed || !isCurrentAccount()) return false;
      emit(
        state.copyWith(
          items: List.unmodifiable([
            for (final item in state.items) item.markRead(),
          ]),
          unreadCount: result.unreadCount,
          clearActionError: true,
        ),
      );
      return true;
    } catch (error) {
      if (isClosed) return false;
      emit(state.copyWith(actionError: _mutationError(error)));
      return false;
    } finally {
      _markingAll = false;
    }
  }

  String _mutationError(Object error) {
    final status = error is DioException ? error.response?.statusCode : null;
    if (status == 401) return NotificationStrings.signInRequired;
    return NotificationStrings.markReadFailed;
  }
}
