import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/models/backend_chat.dart';
import 'package:hywork/features/chat/data/backend_chat_mapper.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/models/chat_message.dart';
import 'package:hywork/features/chat/utils/chat_message_labels.dart';

class ChatInboxState {
  const ChatInboxState({
    this.conversations = const [],
    this.query = '',
    this.unreadOnly = false,
    this.loading = false,
    this.refreshing = false,
    this.loadingMore = false,
    this.page = 0,
    this.hasMore = false,
    this.error,
  });

  final List<ChatConversation> conversations;
  final String query;
  final bool unreadOnly;
  final bool loading;
  final bool refreshing;
  final bool loadingMore;
  final int page;
  final bool hasMore;
  final String? error;

  List<ChatConversation> get filteredConversations {
    if (!unreadOnly) return conversations;
    return conversations
        .where((conversation) => conversation.unreadCount > 0)
        .toList(growable: false);
  }

  bool get hasUnread => conversations.any((chat) => chat.unreadCount > 0);

  ChatInboxState copyWith({
    List<ChatConversation>? conversations,
    String? query,
    bool? unreadOnly,
    bool? loading,
    bool? refreshing,
    bool? loadingMore,
    int? page,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return ChatInboxState(
      conversations: conversations ?? this.conversations,
      query: query ?? this.query,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      loading: loading ?? this.loading,
      refreshing: refreshing ?? this.refreshing,
      loadingMore: loadingMore ?? this.loadingMore,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Inbox backed by `ApiChatsRepository` (`GET /chats` with `q` / page / limit).
class ChatInboxCubit extends Cubit<ChatInboxState> {
  ChatInboxCubit(
    this._repository, {
    required this.isCurrentAccount,
    RealtimeSocketClient? realtime,
  }) : super(const ChatInboxState(loading: true)) {
    _bindRealtime(realtime);
    if (isCurrentAccount()) {
      unawaited(load());
    } else {
      emit(const ChatInboxState());
    }
  }

  final ApiChatsRepository _repository;
  final bool Function() isCurrentAccount;

  static const _pageSize = 20;

  int _listRevision = 0;
  Future<void>? _loadMoreInFlight;
  Future<void>? _refreshInFlight;
  Timer? _searchDebounce;
  StreamSubscription<RealtimeEvent>? _realtimeEvents;
  final Set<String> _deletedMessageIds = {};

  void _bindRealtime(RealtimeSocketClient? realtime) {
    if (realtime == null) return;
    _realtimeEvents = realtime.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (isClosed || !isCurrentAccount()) return;
    switch (event) {
      case RealtimeRecovered():
        unawaited(_coalescedRefresh());
      case RealtimeChatMessage(
        :final conversationId,
        :final message,
        :final unread,
      ):
        _applySocketMessage(
          conversationId: conversationId,
          message: message,
          unread: unread,
        );
      case RealtimeChatMessageDeleted(:final conversationId, :final messageId):
        _applySocketDeleted(
          conversationId: conversationId,
          messageId: messageId,
        );
      case RealtimeChatUnread(:final conversationId, :final unread):
        _applyConversationUnread(conversationId, unread);
      default:
        break;
    }
  }

  Future<void> _coalescedRefresh() {
    if (_refreshInFlight != null) return _refreshInFlight!;
    late final Future<void> future;
    future = refresh().whenComplete(() {
      if (identical(_refreshInFlight, future)) _refreshInFlight = null;
    });
    _refreshInFlight = future;
    return future;
  }

  void _applySocketMessage({
    required String conversationId,
    required BackendChatMessage message,
    required int? unread,
  }) {
    if (_deletedMessageIds.contains(message.id) && !message.deleted) {
      return;
    }
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index < 0) {
      // Do not fabricate conversation metadata — refresh authoritative list.
      unawaited(_coalescedRefresh());
      return;
    }

    final current = state.conversations[index];
    final mapped = chatMessageFromBackend(message);
    final preview = chatMessagePreview(mapped);
    final nextUnread = unread != null
        ? (unread < 0 ? 0 : unread)
        : (mapped.isMine
              ? current.unreadCount
              : current.unreadCount + (mapped.deleted ? 0 : 1));
    final updated = current.copyWith(
      lastMessage: preview,
      lastMessageAt: mapped.sentAt,
      unreadCount: nextUnread,
    );
    final others = [
      for (final item in state.conversations)
        if (item.id != conversationId) item,
    ];
    emit(
      state.copyWith(conversations: List.unmodifiable([updated, ...others])),
    );
  }

  void _applySocketDeleted({
    required String conversationId,
    required String messageId,
  }) {
    _deletedMessageIds.add(messageId);
    final index = state.conversations.indexWhere(
      (conversation) => conversation.id == conversationId,
    );
    if (index < 0) {
      unawaited(_coalescedRefresh());
      return;
    }
    // Preview text is not keyed by message id — refresh metadata via REST.
    unawaited(_coalescedRefresh());
  }

  void _applyConversationUnread(String conversationId, int unread) {
    if (isClosed) return;
    final safe = unread < 0 ? 0 : unread;
    final updated = state.conversations
        .map((conversation) {
          if (conversation.id != conversationId) return conversation;
          return conversation.copyWith(unreadCount: safe);
        })
        .toList(growable: false);
    emit(state.copyWith(conversations: List.unmodifiable(updated)));
  }

  @override
  Future<void> close() async {
    _searchDebounce?.cancel();
    await _realtimeEvents?.cancel();
    _realtimeEvents = null;
    return super.close();
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

  void search(String query) {
    if (isClosed) return;
    emit(state.copyWith(query: query));
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 320), () {
      if (!isClosed) unawaited(load());
    });
  }

  void toggleUnreadFilter() {
    if (isClosed) return;
    emit(state.copyWith(unreadOnly: !state.unreadOnly));
  }

  /// Marks each **currently loaded** unread chat via `POST /chats/{id}/read`.
  ///
  /// There is no bulk mark-all chats endpoint in API 0.20.0. Never reports full
  /// success when unloaded unread chats may remain (`hasMore`) or when
  /// `GET /chats/unread-count` still reports unread after the attempt.
  Future<bool> markAllAsRead() async {
    if (isClosed || !isCurrentAccount()) return false;
    final coverageIncomplete = state.hasMore;
    final targets = state.conversations
        .where((chat) => chat.unreadCount > 0)
        .map((chat) => chat.id)
        .toList(growable: false);

    if (targets.isEmpty) {
      return _confirmMarkAllComplete(coverageIncomplete: coverageIncomplete);
    }

    var failures = 0;
    for (final id in targets) {
      if (isClosed || !isCurrentAccount()) return false;
      try {
        await _repository.markRead(id);
        if (isClosed || !isCurrentAccount()) return false;
        markAsRead(id);
      } catch (_) {
        failures++;
      }
    }
    if (isClosed) return false;
    await refresh();
    if (isClosed) return false;

    final stillLoadedUnread = state.conversations.any(
      (chat) => chat.unreadCount > 0,
    );
    final ok = await _confirmMarkAllComplete(
      coverageIncomplete:
          coverageIncomplete || stillLoadedUnread || failures > 0,
    );
    return ok && failures == 0 && !stillLoadedUnread;
  }

  /// Uses authoritative unread-count when available; never claims success while
  /// more inbox pages (or a positive badge) indicate remaining unread chats.
  Future<bool> _confirmMarkAllComplete({
    required bool coverageIncomplete,
  }) async {
    if (isClosed || !isCurrentAccount()) return false;
    try {
      final badge = await _repository.unreadCount();
      if (isClosed || !isCurrentAccount()) return false;
      if (badge.chats > 0 || badge.messages > 0) {
        emit(state.copyWith(error: ChatStrings.markAllReadPartial));
        return false;
      }
      return true;
    } catch (_) {
      if (coverageIncomplete) {
        emit(state.copyWith(error: ChatStrings.markAllReadPartial));
        return false;
      }
      return true;
    }
  }

  void markAsRead(String conversationId) {
    if (isClosed) return;
    final updated = state.conversations
        .map((conversation) {
          if (conversation.id != conversationId) return conversation;
          return conversation.copyWith(unreadCount: 0);
        })
        .toList(growable: false);
    emit(state.copyWith(conversations: updated));
  }

  void updateConversationPreview(String conversationId, ChatMessage? message) {
    if (isClosed) return;
    final updated = state.conversations
        .map((conversation) {
          if (conversation.id != conversationId) return conversation;
          return conversation.copyWith(
            lastMessage: chatMessagePreview(message),
            lastMessageAt: message?.sentAt ?? conversation.lastMessageAt,
          );
        })
        .toList(growable: false);
    emit(state.copyWith(conversations: updated));
  }

  void upsertConversation(ChatConversation conversation) {
    if (isClosed) return;
    final others = state.conversations
        .where((item) => item.id != conversation.id)
        .toList();
    emit(
      state.copyWith(
        conversations: List.unmodifiable([conversation, ...others]),
      ),
    );
  }

  Future<void> _runLoad({
    required bool replace,
    required bool keepExisting,
  }) async {
    if (isClosed) return;
    if (!isCurrentAccount()) {
      emit(const ChatInboxState());
      return;
    }

    final revision = replace ? ++_listRevision : _listRevision;
    final page = replace ? 1 : state.page + 1;
    final query = state.query.trim();
    emit(
      state.copyWith(
        loading: replace && !keepExisting,
        refreshing: replace && keepExisting,
        loadingMore: !replace,
        clearError: true,
        conversations: replace && !keepExisting ? const [] : null,
        page: replace && !keepExisting ? 0 : null,
        hasMore: replace && !keepExisting ? false : null,
      ),
    );

    try {
      final result = await _repository.list(
        page: page,
        limit: _pageSize,
        q: query.isEmpty ? null : query,
      );
      if (isClosed || revision != _listRevision || !isCurrentAccount()) return;
      // Drop stale search responses when the query changed mid-flight.
      if (query != state.query.trim()) return;

      final mapped = [
        for (final item in result.items) chatConversationFromListItem(item),
      ];
      final merged = <ChatConversation>[];
      final seen = <String>{};
      if (!replace) {
        for (final item in state.conversations) {
          if (seen.add(item.id)) merged.add(item);
        }
      }
      for (final item in mapped) {
        if (seen.add(item.id)) merged.add(item);
      }

      emit(
        state.copyWith(
          conversations: List.unmodifiable(merged),
          loading: false,
          refreshing: false,
          loadingMore: false,
          page: result.page,
          hasMore: result.page * result.limit < result.total,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed || revision != _listRevision) return;
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          loadingMore: false,
          error: ChatStrings.loadFailed,
        ),
      );
    }
  }
}
