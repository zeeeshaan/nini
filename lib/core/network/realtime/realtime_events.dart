import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Documented Socket.IO event names (Swagger Realtime tag, API 0.20.0).
abstract final class RealtimeEventName {
  static const ready = 'ready';
  static const chatMessage = 'chat:message';
  static const chatRead = 'chat:read';
  static const chatTyping = 'chat:typing';
  static const chatMessageDeleted = 'chat:message_deleted';
  static const chatUnread = 'chat:unread';
  static const notificationNew = 'notification:new';
  static const notificationRead = 'notification:read';
  static const connectError = 'connect_error';

  static const serverEvents = {
    ready,
    chatMessage,
    chatRead,
    chatTyping,
    chatMessageDeleted,
    chatUnread,
    notificationNew,
    notificationRead,
  };
}

/// Global badge counters from the `ready` event.
class RealtimeBadgeUnread {
  const RealtimeBadgeUnread({
    required this.notifications,
    required this.chats,
    required this.chatMessages,
  });

  final int notifications;
  final int chats;
  final int chatMessages;

  factory RealtimeBadgeUnread.fromJson(Map<String, dynamic> json) {
    final notifications = json['notifications'];
    final chats = json['chats'];
    final chatMessages = json['chatMessages'];
    if (notifications is! int ||
        notifications < 0 ||
        chats is! int ||
        chats < 0 ||
        chatMessages is! int ||
        chatMessages < 0) {
      throw const FormatException('Invalid realtime unread badges.');
    }
    return RealtimeBadgeUnread(
      notifications: notifications,
      chats: chats,
      chatMessages: chatMessages,
    );
  }
}

sealed class RealtimeEvent {
  const RealtimeEvent();
}

/// Emitted after a successful reconnect so features can REST-reconcile later.
class RealtimeRecovered extends RealtimeEvent {
  const RealtimeRecovered();
}

class RealtimeReady extends RealtimeEvent {
  const RealtimeReady({required this.userId, required this.unread});

  final String userId;
  final RealtimeBadgeUnread unread;
}

class RealtimeChatMessage extends RealtimeEvent {
  const RealtimeChatMessage({
    required this.conversationId,
    required this.message,
    this.unread,
  });

  final String conversationId;
  final BackendChatMessage message;
  final int? unread;
}

class RealtimeChatRead extends RealtimeEvent {
  const RealtimeChatRead({
    required this.conversationId,
    required this.readBy,
    required this.readAt,
  });

  final String conversationId;
  final String readBy;
  final DateTime readAt;
}

class RealtimeChatTyping extends RealtimeEvent {
  const RealtimeChatTyping({
    required this.conversationId,
    required this.userId,
    required this.typing,
  });

  final String conversationId;
  final String userId;
  final bool typing;
}

class RealtimeChatMessageDeleted extends RealtimeEvent {
  const RealtimeChatMessageDeleted({
    required this.conversationId,
    required this.messageId,
  });

  final String conversationId;
  final String messageId;
}

class RealtimeChatUnread extends RealtimeEvent {
  const RealtimeChatUnread({
    required this.conversationId,
    required this.unread,
  });

  final String conversationId;
  final int unread;
}

class RealtimeNotificationNew extends RealtimeEvent {
  const RealtimeNotificationNew({
    required this.notification,
    required this.unreadCount,
  });

  final BackendNotification notification;
  final int unreadCount;
}

class RealtimeNotificationRead extends RealtimeEvent {
  const RealtimeNotificationRead({
    required this.unreadCount,
    this.ids = const [],
    this.all = false,
  });

  final List<String> ids;
  final bool all;
  final int unreadCount;
}

class RealtimeUnknownEvent extends RealtimeEvent {
  const RealtimeUnknownEvent({required this.name});

  final String name;
}

class RealtimeMalformedEvent extends RealtimeEvent {
  const RealtimeMalformedEvent({required this.name, required this.error});

  final String name;
  final Object error;
}

class RealtimeAuthFailure extends RealtimeEvent {
  const RealtimeAuthFailure({required this.code});

  /// Documented codes: `not_logged_in`, `session_expired`, `account_unavailable`.
  final String code;
}

bool isRealtimeBackendId(String value) => ProfileCategory.isBackendId(value);
