import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/models/backend_chat.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/models/chat_message.dart';

/// Maps Swagger Chat payloads onto the existing UI models.
ChatConversation chatConversationFromListItem(BackendChatListItem item) {
  return ChatConversation(
    id: item.id,
    name: _peerDisplayName(item.user),
    lastMessage: backendChatMessagePreview(item.lastMessage),
    lastMessageAt:
        item.lastMessageAt ??
        item.lastMessage?.createdAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    unreadCount: item.unreadCount,
    avatarAsset: item.user.avatarUrl,
    isBlocked: item.iBlocked,
    peerUserId: item.user.id,
    canSend: item.canSend,
  );
}

ChatConversation chatConversationFromDetail(BackendChatDetail detail) {
  return ChatConversation(
    id: detail.id,
    name: _peerDisplayName(detail.user),
    lastMessage: '',
    lastMessageAt:
        detail.lastMessageAt ??
        DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    unreadCount: detail.unreadCount,
    avatarAsset: detail.user.avatarUrl,
    isBlocked: detail.iBlocked,
    peerUserId: detail.user.id,
    canSend: detail.canSend,
    cannotSendReason: detail.cannotSendReason,
  );
}

ChatMessage chatMessageFromBackend(BackendChatMessage message) {
  final deleted = message.deleted;
  // Documented `readAt` only — never invent delivered/read without it.
  final deliveryStatus = !deleted && message.isMine && message.readAt != null
      ? ChatDeliveryStatus.read
      : ChatDeliveryStatus.sent;
  return ChatMessage(
    id: message.id,
    conversationId: message.conversationId,
    text: deleted ? '' : (message.text ?? ''),
    sentAt: message.createdAt,
    isMine: message.isMine,
    deliveryStatus: deliveryStatus,
    deleted: deleted,
    type: message.type,
    imageUrl: deleted ? null : message.imageUrl,
  );
}

/// Newest-first API page → chronological (oldest → newest) for the reverse list.
List<ChatMessage> chronologicalMessagesFromBackend(
  List<BackendChatMessage> newestFirst,
) {
  final chronological = <ChatMessage>[
    for (final message in newestFirst.reversed) chatMessageFromBackend(message),
  ];
  return List.unmodifiable(chronological);
}

String backendChatMessagePreview(BackendChatMessage? message) {
  if (message == null || message.deleted) return AppStrings.noMessages;
  if (!message.isKnownType) return AppStrings.noMessages;
  switch (message.type) {
    case BackendChatMessageType.image:
      final text = message.text?.trim() ?? '';
      return text.isEmpty ? AppStrings.photo : text;
    case BackendChatMessageType.system:
      return message.text?.trim().isNotEmpty == true
          ? message.text!.trim()
          : AppStrings.noMessages;
    case BackendChatMessageType.text:
      final text = message.text?.trim() ?? '';
      return text.isEmpty ? AppStrings.noMessages : text;
    default:
      return AppStrings.noMessages;
  }
}

String _peerDisplayName(BackendChatUser user) {
  final name = user.name?.trim() ?? '';
  if (name.isNotEmpty) return name;
  final username = user.username?.trim() ?? '';
  if (username.isNotEmpty) return username;
  return '';
}
