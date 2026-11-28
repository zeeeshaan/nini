import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification_mapper.dart';

import 'notifications_state.dart';
export 'notifications_state.dart';

/// Account-scoped inbox backed by `ApiNotificationsRepository` + Phase D
/// Socket.IO live updates on the shared [RealtimeSocketClient].
class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit(
    this._repository, {
    required this.isCurrentAccount,
    RealtimeSocketClient? realtime,
  }) : super(const NotificationsState(loading: true)) {
    _bindRealtime(realtime);
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
  bool _unreadQueued = false;
  Future<void>? _refreshInFlight;
  bool _refreshQueued = false;
  final Set<String> _markingIds = {};
  bool _markingAll = false;
  bool _listLoaded = false;
  StreamSubscription<RealtimeEvent>? _realtimeEvents;

  /// Backend IDs confirmed read locally or via socket — stale REST cannot
  /// restore them as unread. Cubit-scoped (cleared on close / account switch);
  /// not hard-capped — FIFO eviction would allow unread regressions.
  final Set<String> _confirmedReadIds = {};

  /// Live inserts that must survive an in-flight page-1 REST refresh.
  /// Pruned when REST observes the same id; cleared on full reload.
  final Set<String> _liveInsertedIds = {};

  void _rememberId(Set<String> target, String id) {
    target.add(id);
  }

  void _bindRealtime(RealtimeSocketClient? realtime) {
    if (realtime == null) return;
    _realtimeEvents = realtime.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (isClosed || !isCurrentAccount()) return;
    switch (event) {
      case RealtimeReady(:final unread):
        applySocketUnreadCount(unread.notifications);
      case RealtimeRecovered():
        unawaited(_recoverAfterRealtime());
      case RealtimeNotificationNew(:final notification, :final unreadCount):
        _applySocketNotificationNew(notification, unreadCount);
      case RealtimeNotificationRead(:final ids, :final all, :final unreadCount):
        _applySocketNotificationRead(
          ids: ids,
          all: all,
          unreadCount: unreadCount,
        );
      default:
        break;
    }
  }

  Future<void> _recoverAfterRealtime() async {
    if (isClosed || !isCurrentAccount()) return;
    unawaited(refreshUnreadCount());
    if (_listLoaded) {
      unawaited(refresh());
    }
  }

  /// Authoritative unread from Socket.IO (`ready` / `notification:*`).
  void applySocketUnreadCount(int count) {
    if (isClosed || !isCurrentAccount()) return;
    if (count < 0) return;
    // Invalidate in-flight REST so a stale response cannot overwrite socket.
    _unreadRevision++;
    emit(state.copyWith(unreadCount: count));
  }

  void _applySocketNotificationNew(
    BackendNotification notification,
    int unreadCount,
  ) {
    if (isClosed || !isCurrentAccount()) return;
    applySocketUnreadCount(unreadCount);

    if (!_listLoaded) {
      // List not loaded — badge only; do not fabricate a partial inbox.
      return;
    }

    final mapped = appNotificationFromBackend(notification);
    if (_confirmedReadIds.contains(mapped.id)) {
      final read = mapped.markRead();
      _upsertLoaded(read, prependIfNew: true);
      return;
    }
    _rememberId(_liveInsertedIds, mapped.id);
    _upsertLoaded(mapped, prependIfNew: true);
  }

  void _applySocketNotificationRead({
    required List<String> ids,
    required bool all,
    required int unreadCount,
  }) {
    if (isClosed || !isCurrentAccount()) return;
    applySocketUnreadCount(unreadCount);

    if (!_listLoaded) return;

    if (all) {
      for (final item in state.items) {
        _rememberId(_confirmedReadIds, item.id);
      }
      emit(
        state.copyWith(
          items: List.unmodifiable([
            for (final item in state.items) item.markRead(),
          ]),
        ),
      );
      return;
    }

    if (ids.isEmpty) return;
    for (final id in ids) {
      _rememberId(_confirmedReadIds, id);
    }
    var changed = false;
    final updated = <AppNotification>[];
    for (final item in state.items) {
      if (ids.contains(item.id)) {
        if (item.unreadCount != 0) changed = true;
        updated.add(item.markRead());
      } else {
        updated.add(item);
      }
    }
    if (changed) {
      emit(state.copyWith(items: List.unmodifiable(updated)));
    }
  }

  void _upsertLoaded(AppNotification item, {required bool prependIfNew}) {
    if (isClosed) return;
    final index = state.items.indexWhere((existing) => existing.id == item.id);
    if (index >= 0) {
      final prior = state.items[index];
      final next = _preferMonotonicRead(prior, item);
      if (next.unreadCount == prior.unreadCount &&
          next.title == prior.title &&
          next.message == prior.message &&
          next.titleFa == prior.titleFa &&
          next.messageFa == prior.messageFa) {
        return;
      }
      final items = [...state.items];
      items[index] = next;
      emit(state.copyWith(items: List.unmodifiable(items)));
      return;
    }
    if (!prependIfNew) return;
    emit(
      state.copyWith(
        items: List.unmodifiable([item, ...state.items]),
        loading: false,
        refreshing: false,
        clearError: true,
      ),
    );
  }

  AppNotification _preferMonotonicRead(
    AppNotification prior,
    AppNotification incoming,
  ) {
    if (_confirmedReadIds.contains(prior.id) ||
        (prior.unreadCount == 0 && incoming.unreadCount != 0)) {
      return incoming.unreadCount == 0 ? incoming : incoming.markRead();
    }
    return incoming;
  }

  void search(String query) {
    if (isClosed) return;
    emit(state.copyWith(query: query));
  }

  Future<void> load() => _runLoad(replace: true, keepExisting: false);

  /// Coalesces concurrent refreshes and queues one trailing pass so a push that
  /// arrives during an in-flight request still updates the inbox and badge.
  Future<void> refresh() {
    if (!isCurrentAccount()) return Future.value();
    if (_refreshInFlight != null) {
      _refreshQueued = true;
      return _refreshInFlight!;
    }
    late final Future<void> future;
    future = _runLoad(replace: true, keepExisting: true).whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
      if (_refreshQueued) {
        _refreshQueued = false;
        unawaited(refresh());
      }
    });
    _refreshInFlight = future;
    return future;
  }

  Future<void> loadMore() {
    if (state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore ||
        !isCurrentAccount()) {
      return Future.value();
    }
    return _loadMoreInFlight ??= _loadMoreUntilProgress().whenComplete(
      () => _loadMoreInFlight = null,
    );
  }

  /// Page/limit offsets shift when live inserts land above the fold. A single
  /// next page can be duplicate-only; advance (bounded) until a new id appears
  /// or the server reports no more pages — avoiding permanent skips.
  Future<void> _loadMoreUntilProgress() async {
    const maxDuplicateOnlyPages = 5;
    for (var attempt = 0; attempt < maxDuplicateOnlyPages; attempt++) {
      if (isClosed ||
          !isCurrentAccount() ||
          !state.hasMore ||
          state.loading ||
          state.refreshing) {
        return;
      }
      final before = {for (final item in state.items) item.id};
      await _runLoad(replace: false, keepExisting: true);
      if (isClosed || !isCurrentAccount()) return;
      final added = state.items.any((item) => !before.contains(item.id));
      if (added || !state.hasMore) return;
    }
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
    final previous = List<AppNotification>.from(state.items);
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
        for (final item in result.items)
          _applyConfirmedRead(appNotificationFromBackend(item)),
      ];
      final merged = _mergeItems(
        replace: replace,
        keepExisting: keepExisting,
        previous: previous,
        incoming: mapped,
      );

      _listLoaded = true;
      if (replace && !keepExisting) {
        _liveInsertedIds.clear();
      } else if (replace) {
        _liveInsertedIds.removeWhere(
          (id) => mapped.any((item) => item.id == id),
        );
      }

      emit(
        state.copyWith(
          items: List.unmodifiable(merged),
          loading: false,
          refreshing: false,
          loadingMore: false,
          page: result.page,
          hasMore: result.page * result.limit < result.total,
          // Dedicated unread-count / socket remain authoritative when known.
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

  List<AppNotification> _mergeItems({
    required bool replace,
    required bool keepExisting,
    required List<AppNotification> previous,
    required List<AppNotification> incoming,
  }) {
    if (replace && !keepExisting) {
      return incoming;
    }

    if (!replace) {
      final merged = <AppNotification>[];
      final seen = <String>{};
      for (final item in state.items) {
        if (seen.add(item.id)) merged.add(item);
      }
      for (final item in incoming) {
        if (seen.add(item.id)) {
          merged.add(item);
        } else {
          final index = merged.indexWhere((existing) => existing.id == item.id);
          if (index >= 0) {
            merged[index] = _preferMonotonicRead(merged[index], item);
          }
        }
      }
      return merged;
    }

    // replace + keepExisting: REST page is authoritative order, but preserve
    // live socket inserts that arrived while the request was in flight.
    final byId = <String, AppNotification>{
      for (final item in previous) item.id: item,
      // Include current state so in-flight socket inserts are not dropped.
      for (final item in state.items) item.id: item,
    };
    for (final item in incoming) {
      final prior = byId[item.id];
      byId[item.id] = prior == null ? item : _preferMonotonicRead(prior, item);
    }

    final restIds = {for (final item in incoming) item.id};
    final liveExtras = <AppNotification>[];
    for (final id in _liveInsertedIds) {
      if (restIds.contains(id)) continue;
      final item = byId[id];
      if (item != null) liveExtras.add(item);
    }

    final ordered = <AppNotification>[
      ...liveExtras,
      for (final item in incoming) byId[item.id]!,
    ];
    final seen = <String>{};
    return [
      for (final item in ordered)
        if (seen.add(item.id)) item,
    ];
  }

  AppNotification _applyConfirmedRead(AppNotification item) {
    if (_confirmedReadIds.contains(item.id) && item.unreadCount != 0) {
      return item.markRead();
    }
    return item;
  }

  Future<void> refreshUnreadCount() {
    if (!isCurrentAccount()) return Future.value();
    if (_unreadInFlight != null) {
      // Push may land while the previous unread request is still in flight.
      _unreadQueued = true;
      return _unreadInFlight!;
    }
    late final Future<void> future;
    future = _runUnreadCount().whenComplete(() {
      if (identical(_unreadInFlight, future)) _unreadInFlight = null;
      if (_unreadQueued) {
        _unreadQueued = false;
        unawaited(refreshUnreadCount());
      }
    });
    _unreadInFlight = future;
    return future;
  }

  Future<void> _runUnreadCount() async {
    if (isClosed || !isCurrentAccount()) return;
    final revision = ++_unreadRevision;
    try {
      final count = await _repository.unreadCount();
      if (isClosed || revision != _unreadRevision || !isCurrentAccount()) {
        return;
      }
      if (count < 0) return;
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
    return _markReadRequest(id, index: index, item: item);
  }

  /// Marks a notification read from a push tap even when the list is unloaded.
  Future<bool> markReadFromPush(String id) async {
    if (isClosed || !isCurrentAccount()) return false;
    final trimmed = id.trim();
    if (trimmed.isEmpty) return false;
    final index = state.items.indexWhere((item) => item.id == trimmed);
    if (index >= 0) {
      final item = state.items[index];
      if (item.unreadCount == 0) return true;
      return _markReadRequest(trimmed, index: index, item: item);
    }
    return _markReadRequest(trimmed);
  }

  Future<bool> _markReadRequest(
    String id, {
    int? index,
    AppNotification? item,
  }) async {
    if (!_markingIds.add(id)) return false;
    emit(state.copyWith(clearActionError: true));
    try {
      final result = await _repository.markRead(ids: [id]);
      if (isClosed || !isCurrentAccount()) return false;
      _rememberId(_confirmedReadIds, id);
      _unreadRevision++;
      if (index != null && item != null && index < state.items.length) {
        final items = [...state.items];
        items[index] = item.markRead();
        emit(
          state.copyWith(
            items: List.unmodifiable(items),
            unreadCount: result.unreadCount < 0 ? 0 : result.unreadCount,
            clearActionError: true,
          ),
        );
      } else {
        emit(
          state.copyWith(
            unreadCount: result.unreadCount < 0 ? 0 : result.unreadCount,
            clearActionError: true,
          ),
        );
      }
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
      for (final item in state.items) {
        _rememberId(_confirmedReadIds, item.id);
      }
      _unreadRevision++;
      emit(
        state.copyWith(
          items: List.unmodifiable([
            for (final item in state.items) item.markRead(),
          ]),
          unreadCount: result.unreadCount < 0 ? 0 : result.unreadCount,
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

  @override
  Future<void> close() async {
    await _realtimeEvents?.cancel();
    _realtimeEvents = null;
    return super.close();
  }
}
