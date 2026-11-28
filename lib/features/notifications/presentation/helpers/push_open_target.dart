import 'dart:convert';

import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Documented Swagger 0.20.0 FCM `data` fields for notification opens.
///
/// Push `data` includes `type`, `targetType`, `targetId`, `notificationId`,
/// and for chat also `conversationId` / `messageId`.
class PushOpenTarget {
  const PushOpenTarget({
    this.targetType,
    this.targetId,
    this.conversationId,
    this.notificationId,
    this.messageId,
    this.type,
  });

  final String? targetType;
  final String? targetId;
  final String? conversationId;
  final String? notificationId;
  final String? messageId;
  final String? type;

  /// Prefer explicit `targetType`; otherwise infer from notification `type`.
  String? get resolvedTargetType {
    final explicit = targetType?.trim();
    if (explicit != null && explicit.isNotEmpty) return explicit;
    final raw = type?.trim().toLowerCase() ?? '';
    if (raw.startsWith('chat')) return NotificationTargetType.chat;
    if (raw.startsWith('post')) return NotificationTargetType.post;
    if (raw.startsWith('order')) return NotificationTargetType.order;
    if (raw.startsWith('user') || raw.contains('follow')) {
      return NotificationTargetType.user;
    }
    return null;
  }

  bool get hasDestination =>
      chatId != null || postId != null || userId != null || isOrder;

  /// Chat destination prefers `conversationId`, then `targetId` when type is chat.
  String? get chatId {
    final conversation = conversationId?.trim();
    if (conversation != null &&
        conversation.isNotEmpty &&
        ProfileCategory.isBackendId(conversation)) {
      return conversation;
    }
    if (resolvedTargetType == NotificationTargetType.chat) {
      final id = targetId?.trim();
      if (id != null && id.isNotEmpty && ProfileCategory.isBackendId(id)) {
        return id;
      }
    }
    return null;
  }

  String? get postId {
    if (resolvedTargetType != NotificationTargetType.post) return null;
    final id = targetId?.trim();
    if (id == null || id.isEmpty || !ProfileCategory.isBackendId(id)) {
      return null;
    }
    return id;
  }

  String? get userId {
    if (resolvedTargetType != NotificationTargetType.user) return null;
    final id = targetId?.trim();
    if (id == null || id.isEmpty || !ProfileCategory.isBackendId(id)) {
      return null;
    }
    return id;
  }

  bool get isOrder => resolvedTargetType == NotificationTargetType.order;

  factory PushOpenTarget.fromData(Map<String, dynamic> data) {
    String? read(String key) {
      final value = data[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    return PushOpenTarget(
      targetType: read('targetType'),
      targetId: read('targetId'),
      conversationId: read('conversationId'),
      notificationId: read('notificationId'),
      messageId: read('messageId'),
      type: read('type'),
    );
  }

  /// Local-notification payload: JSON object of the FCM data map.
  factory PushOpenTarget.fromPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) {
      return const PushOpenTarget();
    }
    try {
      final decoded = jsonDecode(payload);
      if (decoded is! Map) return const PushOpenTarget();
      return PushOpenTarget.fromData(
        Map<String, dynamic>.from(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        ),
      );
    } catch (_) {
      return const PushOpenTarget();
    }
  }

  /// Compact JSON for local notification taps (documented FCM keys only).
  String toPayload() {
    final map = <String, String>{
      'type': ?type,
      'targetType': ?targetType,
      'targetId': ?targetId,
      'conversationId': ?conversationId,
      'notificationId': ?notificationId,
      'messageId': ?messageId,
    };
    return jsonEncode(map);
  }
}
