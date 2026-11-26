import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
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
  ChatUnreadCubit(this._repository, {required this.isCurrentAccount})
    : super(const ChatUnreadState()) {
    if (isCurrentAccount()) {
      unawaited(refresh());
    }
  }

  final ApiChatsRepository _repository;
  final bool Function() isCurrentAccount;

  int _revision = 0;
  Future<void>? _inFlight;

  Future<void> refresh() {
    if (!isCurrentAccount()) return Future.value();
    if (_inFlight != null) return _inFlight!;
    final future = _run();
    _inFlight = future.whenComplete(() {
      if (identical(_inFlight, future)) _inFlight = null;
    });
    return _inFlight!;
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
}
