import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';

class ChatUnreadState {
  const ChatUnreadState({this.chats, this.messages});

  /// Unread conversation count from `GET /chats/unread-count`.
  final int? chats;

  /// Unread message count from `GET /chats/unread-count`.
  final int? messages;

  /// Inbox button badge uses unread **conversation** count.
  int get badgeCount => chats ?? 0;

  ChatUnreadState copyWith({int? chats, int? messages}) => ChatUnreadState(
    chats: chats ?? this.chats,
    messages: messages ?? this.messages,
  );
}

/// Shared account-scoped unread chats/messages badge state.
class ChatUnreadCubit extends Cubit<ChatUnreadState> {
  ChatUnreadCubit(
    this._repository, {
    required this.isCurrentAccount,
    RealtimeSocketClient? realtime,
  }) : super(const ChatUnreadState()) {
    _bindRealtime(realtime);
    if (isCurrentAccount()) {
      unawaited(refresh());
    }
  }

  final ApiChatsRepository _repository;
  final bool Function() isCurrentAccount;

  int _revision = 0;
  Future<void>? _inFlight;
  StreamSubscription<RealtimeEvent>? _realtimeEvents;

  void _bindRealtime(RealtimeSocketClient? realtime) {
    if (realtime == null) return;
    _realtimeEvents = realtime.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (isClosed || !isCurrentAccount()) return;
    switch (event) {
      case RealtimeReady(:final unread):
        applyReadyUnread(
          chats: unread.chats,
          chatMessages: unread.chatMessages,
        );
      case RealtimeRecovered():
        unawaited(refresh());
      case RealtimeChatUnread():
      case RealtimeChatMessage():
        // Per-conversation `unread` is not the global badge — REST refresh.
        unawaited(refresh());
      default:
        break;
    }
  }

  Future<void> refresh() {
    if (!isCurrentAccount()) return Future.value();
    if (_inFlight != null) return _inFlight!;
    late final Future<void> future;
    future = _run().whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    _inFlight = future;
    return future;
  }

  Future<void> _run() async {
    if (isClosed || !isCurrentAccount()) return;
    final revision = ++_revision;
    try {
      final count = await _repository.unreadCount();
      if (isClosed || revision != _revision || !isCurrentAccount()) return;
      emit(ChatUnreadState(chats: count.chats, messages: count.messages));
    } catch (_) {
      // Keep the previous badge value; never fabricate zero on failure.
      if (isClosed || revision != _revision) return;
    }
  }

  /// Authoritative counters from Socket.IO `ready.unread`.
  void applyReadyUnread({required int chats, required int chatMessages}) {
    if (isClosed || !isCurrentAccount()) return;
    if (chats < 0 || chatMessages < 0) return;
    // Invalidate in-flight REST so a stale response cannot overwrite ready.
    _revision++;
    emit(ChatUnreadState(chats: chats, messages: chatMessages));
  }

  /// Optimistic local adjustment after a confirmed mark-read (not a fallback).
  void applyConversationRead() {
    if (isClosed || state.chats == null) return;
    final next = state.chats! - 1;
    emit(state.copyWith(chats: next < 0 ? 0 : next));
  }

  void clear() {
    _revision++;
    if (!isClosed) emit(const ChatUnreadState());
  }

  @override
  Future<void> close() async {
    await _realtimeEvents?.cancel();
    _realtimeEvents = null;
    return super.close();
  }
}
