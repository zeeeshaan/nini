import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';

/// Parses Socket.IO payloads using documented Swagger Realtime shapes only.
abstract final class RealtimeEventParser {
  static RealtimeEvent parse(String name, dynamic raw) {
    try {
      final data = _asMap(raw);
      return switch (name) {
        RealtimeEventName.ready => _ready(data),
        RealtimeEventName.chatMessage => _chatMessage(data),
        RealtimeEventName.chatRead => _chatRead(data),
        RealtimeEventName.chatTyping => _chatTyping(data),
        RealtimeEventName.chatMessageDeleted => _chatMessageDeleted(data),
        RealtimeEventName.chatUnread => _chatUnread(data),
        RealtimeEventName.notificationNew => _notificationNew(data),
        RealtimeEventName.notificationRead => _notificationRead(data),
        _ => RealtimeUnknownEvent(name: name),
      };
    } catch (error) {
      return RealtimeMalformedEvent(name: name, error: error);
    }
  }

  static RealtimeAuthFailure? parseConnectError(dynamic raw) {
    final code = _connectErrorCode(raw);
    if (code == null) return null;
    const known = {'not_logged_in', 'session_expired', 'account_unavailable'};
    if (!known.contains(code)) return null;
    return RealtimeAuthFailure(code: code);
  }

  static String? _connectErrorCode(dynamic raw) {
    if (raw is String) {
      final value = raw.trim();
      return value.isEmpty ? null : value;
    }
    if (raw is Map) {
      final message = raw['message'] ?? raw['data'] ?? raw['error'];
      if (message is String && message.trim().isNotEmpty) {
        return message.trim();
      }
    }
    final text = raw?.toString().trim();
    if (text == null || text.isEmpty) return null;
    for (final code in const [
      'not_logged_in',
      'session_expired',
      'account_unavailable',
    ]) {
      if (text.contains(code)) return code;
    }
    return null;
  }

  static RealtimeReady _ready(Map<String, dynamic> json) {
    final userId = json['userId'];
    final unreadRaw = json['unread'];
    if (userId is! String ||
        !isRealtimeBackendId(userId) ||
        unreadRaw is! Map) {
      throw const FormatException('Invalid ready event.');
    }
    return RealtimeReady(
      userId: userId,
      unread: RealtimeBadgeUnread.fromJson(
        Map<String, dynamic>.from(unreadRaw),
      ),
    );
  }

  static RealtimeChatMessage _chatMessage(Map<String, dynamic> json) {
    final conversationId = json['conversationId'];
    final messageRaw = json['message'];
    if (conversationId is! String ||
        !isRealtimeBackendId(conversationId) ||
        messageRaw is! Map) {
      throw const FormatException('Invalid chat:message event.');
    }
    final message = BackendChatMessage.fromJson(
      Map<String, dynamic>.from(messageRaw),
    );
    if (message.conversationId != conversationId) {
      throw const FormatException('Invalid chat:message event.');
    }
    return RealtimeChatMessage(
      conversationId: conversationId,
      message: message,
      unread: _optionalNonNegativeInt(json['unread']),
    );
  }

  static RealtimeChatRead _chatRead(Map<String, dynamic> json) {
    final conversationId = json['conversationId'];
    final readBy = json['readBy'];
    final readAtRaw = json['readAt'];
    if (conversationId is! String ||
        !isRealtimeBackendId(conversationId) ||
        readBy is! String ||
        !isRealtimeBackendId(readBy) ||
        readAtRaw is! String) {
      throw const FormatException('Invalid chat:read event.');
    }
    final readAt = DateTime.tryParse(readAtRaw);
    if (readAt == null) {
      throw const FormatException('Invalid chat:read event.');
    }
    return RealtimeChatRead(
      conversationId: conversationId,
      readBy: readBy,
      readAt: readAt,
    );
  }

  static RealtimeChatTyping _chatTyping(Map<String, dynamic> json) {
    final conversationId = json['conversationId'];
    final userId = json['userId'];
    final typing = json['typing'];
    if (conversationId is! String ||
        !isRealtimeBackendId(conversationId) ||
        userId is! String ||
        !isRealtimeBackendId(userId) ||
        typing is! bool) {
      throw const FormatException('Invalid chat:typing event.');
    }
    return RealtimeChatTyping(
      conversationId: conversationId,
      userId: userId,
      typing: typing,
    );
  }

  static RealtimeChatMessageDeleted _chatMessageDeleted(
    Map<String, dynamic> json,
  ) {
    final conversationId = json['conversationId'];
    final messageId = json['messageId'];
    if (conversationId is! String ||
        !isRealtimeBackendId(conversationId) ||
        messageId is! String ||
        !isRealtimeBackendId(messageId)) {
      throw const FormatException('Invalid chat:message_deleted event.');
    }
    return RealtimeChatMessageDeleted(
      conversationId: conversationId,
      messageId: messageId,
    );
  }

  static RealtimeChatUnread _chatUnread(Map<String, dynamic> json) {
    final conversationId = json['conversationId'];
    final unread = json['unread'];
    if (conversationId is! String ||
        !isRealtimeBackendId(conversationId) ||
        unread is! int ||
        unread < 0) {
      throw const FormatException('Invalid chat:unread event.');
    }
    return RealtimeChatUnread(conversationId: conversationId, unread: unread);
  }

  static RealtimeNotificationNew _notificationNew(Map<String, dynamic> json) {
    final notificationRaw = json['notification'];
    final unreadCount = json['unreadCount'];
    if (notificationRaw is! Map || unreadCount is! int || unreadCount < 0) {
      throw const FormatException('Invalid notification:new event.');
    }
    return RealtimeNotificationNew(
      notification: BackendNotification.fromJson(
        Map<String, dynamic>.from(notificationRaw),
      ),
      unreadCount: unreadCount,
    );
  }

  static RealtimeNotificationRead _notificationRead(Map<String, dynamic> json) {
    final unreadCount = json['unreadCount'];
    final all = json['all'];
    final idsRaw = json['ids'];
    if (unreadCount is! int || unreadCount < 0) {
      throw const FormatException('Invalid notification:read event.');
    }
    final markAll = all == true;
    final ids = <String>[];
    if (idsRaw != null) {
      if (idsRaw is! List) {
        throw const FormatException('Invalid notification:read event.');
      }
      for (final id in idsRaw) {
        if (id is! String || !isRealtimeBackendId(id)) {
          throw const FormatException('Invalid notification:read event.');
        }
        ids.add(id);
      }
    }
    if (!markAll && ids.isEmpty && all != false && all != null) {
      throw const FormatException('Invalid notification:read event.');
    }
    return RealtimeNotificationRead(
      ids: List.unmodifiable(ids),
      all: markAll,
      unreadCount: unreadCount,
    );
  }

  static Map<String, dynamic> _asMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw const FormatException('Realtime payload must be an object.');
  }

  static int? _optionalNonNegativeInt(dynamic value) {
    if (value == null) return null;
    if (value is int && value >= 0) return value;
    throw const FormatException('Invalid unread value.');
  }
}
