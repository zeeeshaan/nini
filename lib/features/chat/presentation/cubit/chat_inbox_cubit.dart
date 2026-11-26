import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat_mapper.dart';
import 'package:hywork/features/chat/domain/models/chat_conversation.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/presentation/helpers/chat_message_labels.dart';

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
  ChatInboxCubit(this._repository, {required this.isCurrentAccount})
    : super(const ChatInboxState(loading: true)) {
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
  Timer? _searchDebounce;

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
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

  /// Local-only list adjustment — there is no mark-all chats API in v0.18.0.
  void markAllAsRead() {
    if (isClosed) return;
    final updated = state.conversations
        .map((chat) => chat.copyWith(unreadCount: 0))
        .toList(growable: false);
    emit(state.copyWith(conversations: updated));
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
