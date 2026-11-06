import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/chat/data/demo_chats.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/domain/repositories/chat_messages_repository.dart';
import 'package:nini/features/chat/presentation/helpers/chat_message_labels.dart';

class ChatInboxState {
  const ChatInboxState({
    required this.conversations,
    this.query = '',
    this.unreadOnly = false,
  });

  final List<ChatConversation> conversations;
  final String query;
  final bool unreadOnly;

  List<ChatConversation> get filteredConversations {
    final search = query.trim().toLowerCase();

    return conversations
        .where((conversation) {
          final matchesSearch =
              search.isEmpty ||
              conversation.name.toLowerCase().contains(search) ||
              conversation.lastMessage.toLowerCase().contains(search);

          final matchesUnread = !unreadOnly || conversation.unreadCount > 0;

          return matchesSearch && matchesUnread;
        })
        .toList(growable: false);
  }

  bool get hasUnread => conversations.any((chat) => chat.unreadCount > 0);

  ChatInboxState copyWith({
    List<ChatConversation>? conversations,
    String? query,
    bool? unreadOnly,
  }) {
    return ChatInboxState(
      conversations: conversations ?? this.conversations,
      query: query ?? this.query,
      unreadOnly: unreadOnly ?? this.unreadOnly,
    );
  }
}

class ChatInboxCubit extends Cubit<ChatInboxState> {
  ChatInboxCubit({
    List<ChatConversation>? initialConversations,
    ChatMessagesRepository? repository,
  }) : repository = repository ?? InMemoryChatRepository.instance,
       super(
         ChatInboxState(
           conversations: initialConversations ?? createDemoConversations(),
         ),
       ) {
    refresh();
  }
  final ChatMessagesRepository repository;
  void refresh() {
    final source = repository;
    final existingIds = state.conversations.map((chat) => chat.id).toSet();
    final conversations = [
      if (source is InMemoryChatRepository)
        ...source.conversations.where((chat) => !existingIds.contains(chat.id)),
      ...state.conversations,
    ];
    final chats = conversations
        .map((conversation) {
          final messages = repository.existingMessages(conversation.id);
          return conversation.copyWith(
            isBlocked: repository.isBlocked(conversation.id),
            lastMessage: messages == null
                ? conversation.lastMessage
                : chatMessagePreview(messages.isEmpty ? null : messages.last),
            lastMessageAt: messages == null || messages.isEmpty
                ? conversation.lastMessageAt
                : messages.last.sentAt,
          );
        })
        .toList(growable: false);
    emit(state.copyWith(conversations: chats));
  }

  void search(String query) {
    emit(state.copyWith(query: query));
  }

  void updateConversationPreview(String conversationId, ChatMessage? message) {
    final updated = state.conversations
        .map((conversation) {
          if (conversation.id != conversationId) {
            return conversation;
          }

          return ChatConversation(
            id: conversation.id,
            name: conversation.name,
            lastMessage: chatMessagePreview(message),
            lastMessageAt: message?.sentAt ?? DateTime.now(),
            unreadCount: conversation.unreadCount,
            isSupport: conversation.isSupport,
            avatarAsset: conversation.avatarAsset,
            isBlocked: repository.isBlocked(conversation.id),
          );
        })
        .toList(growable: false);

    emit(state.copyWith(conversations: updated));
  }

  void toggleUnreadFilter() {
    emit(state.copyWith(unreadOnly: !state.unreadOnly));
  }

  void markAsRead(String conversationId) {
    final updated = state.conversations
        .map((conversation) {
          if (conversation.id != conversationId) {
            return conversation;
          }

          return conversation.copyWith(unreadCount: 0);
        })
        .toList(growable: false);

    emit(state.copyWith(conversations: updated));
  }

  void markAllAsRead() {
    final updated = state.conversations
        .map((chat) => chat.copyWith(unreadCount: 0))
        .toList(growable: false);

    emit(state.copyWith(conversations: updated));
  }
}
