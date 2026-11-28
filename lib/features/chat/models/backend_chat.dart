import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Swagger `ChatMessage.type`.
abstract final class BackendChatMessageType {
  static const text = 'text';
  static const image = 'image';
  static const system = 'system';
  static const known = {text, image, system};
}

/// Swagger `ChatDetail.cannotSendReason` documented values.
abstract final class ChatCannotSendReason {
  static const blockedByHywork = 'blocked_by_hywork';
  static const youBlockedUser = 'you_blocked_user';
  static const userBlockedYou = 'user_blocked_you';
  static const userUnavailable = 'user_unavailable';
  static const known = {
    blockedByHywork,
    youBlockedUser,
    userBlockedYou,
    userUnavailable,
  };
}

/// Swagger `ChatMessage.deletedBy`.
abstract final class ChatMessageDeletedBy {
  static const sender = 'sender';
  static const admin = 'admin';
  static const known = {sender, admin};
}

/// Other participant on a chat list/detail payload.
class BackendChatUser {
  const BackendChatUser({
    required this.id,
    this.name,
    this.username,
    this.avatarUrl,
    this.verified = false,
  });

  final String id;
  final String? name;
  final String? username;
  final String? avatarUrl;
  final bool verified;

  factory BackendChatUser.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final username = json['username'];
    final avatarUrl = json['avatarUrl'];
    final verified = json['verified'];
    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        (name != null && name is! String) ||
        (username != null && username is! String) ||
        (avatarUrl != null && avatarUrl is! String) ||
        (verified != null && verified is! bool)) {
      throw const FormatException('Invalid chat user response.');
    }
    return BackendChatUser(
      id: id,
      name: name as String?,
      username: username as String?,
      avatarUrl: avatarUrl as String?,
      verified: verified as bool? ?? false,
    );
  }
}

/// Swagger `ChatMessage`.
class BackendChatMessage {
  const BackendChatMessage({
    required this.id,
    required this.conversationId,
    required this.isMine,
    required this.type,
    required this.deleted,
    required this.createdAt,
    this.senderId,
    this.text,
    this.imageUrl,
    this.deletedBy,
    this.readAt,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final bool isMine;
  final String type;
  final String? text;
  final String? imageUrl;
  final bool deleted;
  final String? deletedBy;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isKnownType => BackendChatMessageType.known.contains(type);

  factory BackendChatMessage.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final conversationId = json['conversationId'];
    final senderId = json['senderId'];
    final isMine = json['isMine'];
    final type = json['type'];
    final text = json['text'];
    final imageUrl = json['imageUrl'];
    final deleted = json['deleted'];
    final deletedBy = json['deletedBy'];
    final readRaw = json['readAt'];
    final createdRaw = json['createdAt'];

    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        conversationId is! String ||
        !ProfileCategory.isBackendId(conversationId) ||
        (senderId != null &&
            (senderId is! String || !ProfileCategory.isBackendId(senderId))) ||
        isMine is! bool ||
        type is! String ||
        type.trim().isEmpty ||
        (text != null && text is! String) ||
        (imageUrl != null && imageUrl is! String) ||
        deleted is! bool ||
        (deletedBy != null && deletedBy is! String) ||
        createdRaw is! String) {
      throw const FormatException('Invalid chat message response.');
    }

    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) {
      throw const FormatException('Invalid chat message response.');
    }

    DateTime? readAt;
    if (readRaw != null) {
      if (readRaw is! String) {
        throw const FormatException('Invalid chat message response.');
      }
      readAt = DateTime.tryParse(readRaw);
      if (readAt == null) {
        throw const FormatException('Invalid chat message response.');
      }
    }

    return BackendChatMessage(
      id: id,
      conversationId: conversationId,
      senderId: senderId as String?,
      isMine: isMine,
      type: type,
      text: text as String?,
      imageUrl: imageUrl as String?,
      deleted: deleted,
      deletedBy: deletedBy as String?,
      readAt: readAt,
      createdAt: createdAt,
    );
  }
}

/// Admin warning shown at the top of a chat.
class BackendChatWarning {
  const BackendChatWarning({
    required this.id,
    required this.message,
    required this.createdAt,
  });

  final String id;
  final String message;
  final DateTime createdAt;

  factory BackendChatWarning.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final message = json['message'];
    final createdRaw = json['createdAt'];
    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        message is! String ||
        message.trim().isEmpty ||
        createdRaw is! String) {
      throw const FormatException('Invalid chat warning response.');
    }
    final createdAt = DateTime.tryParse(createdRaw);
    if (createdAt == null) {
      throw const FormatException('Invalid chat warning response.');
    }
    return BackendChatWarning(id: id, message: message, createdAt: createdAt);
  }
}

/// Temporary HyWork chat block metadata on `ChatDetail`.
class BackendChatHyworkBlock {
  const BackendChatHyworkBlock({this.until, this.reason});

  final DateTime? until;
  final String? reason;

  factory BackendChatHyworkBlock.fromJson(Map<String, dynamic> json) {
    final untilRaw = json['until'];
    final reason = json['reason'];
    if ((untilRaw != null && untilRaw is! String) ||
        (reason != null && reason is! String)) {
      throw const FormatException('Invalid chat block response.');
    }
    DateTime? until;
    if (untilRaw != null) {
      until = DateTime.tryParse(untilRaw as String);
      if (until == null) {
        throw const FormatException('Invalid chat block response.');
      }
    }
    return BackendChatHyworkBlock(until: until, reason: reason as String?);
  }
}

/// Swagger chat list row (subset of detail + last message).
class BackendChatListItem {
  const BackendChatListItem({
    required this.id,
    required this.user,
    required this.unreadCount,
    required this.canSend,
    required this.blockedByHywork,
    required this.iBlocked,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final BackendChatUser user;
  final BackendChatMessage? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final bool canSend;
  final bool blockedByHywork;
  final bool iBlocked;

  factory BackendChatListItem.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final user = json['user'];
    final lastMessage = json['lastMessage'];
    final lastRaw = json['lastMessageAt'];
    final unreadCount = json['unreadCount'];
    final canSend = json['canSend'];
    final blockedByHywork = json['blockedByHywork'];
    final iBlocked = json['iBlocked'];

    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        user is! Map<String, dynamic> ||
        (lastMessage != null && lastMessage is! Map<String, dynamic>) ||
        (lastRaw != null && lastRaw is! String) ||
        unreadCount is! int ||
        unreadCount < 0 ||
        canSend is! bool ||
        blockedByHywork is! bool ||
        iBlocked is! bool) {
      throw const FormatException('Invalid chat list item response.');
    }

    DateTime? lastMessageAt;
    if (lastRaw != null) {
      lastMessageAt = DateTime.tryParse(lastRaw as String);
      if (lastMessageAt == null) {
        throw const FormatException('Invalid chat list item response.');
      }
    }

    return BackendChatListItem(
      id: id,
      user: BackendChatUser.fromJson(user),
      lastMessage: lastMessage == null
          ? null
          : BackendChatMessage.fromJson(lastMessage as Map<String, dynamic>),
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount,
      canSend: canSend,
      blockedByHywork: blockedByHywork,
      iBlocked: iBlocked,
    );
  }
}

/// Swagger `ChatDetail`.
class BackendChatDetail {
  const BackendChatDetail({
    required this.id,
    required this.user,
    required this.canSend,
    required this.iBlocked,
    required this.blockedMe,
    required this.warnings,
    required this.unreadCount,
    this.cannotSendReason,
    this.blockedByHywork,
    this.lastMessageAt,
  });

  final String id;
  final BackendChatUser user;
  final bool canSend;
  final String? cannotSendReason;
  final BackendChatHyworkBlock? blockedByHywork;
  final bool iBlocked;
  final bool blockedMe;
  final List<BackendChatWarning> warnings;
  final int unreadCount;
  final DateTime? lastMessageAt;

  bool get hasKnownCannotSendReason =>
      cannotSendReason == null ||
      ChatCannotSendReason.known.contains(cannotSendReason);

  factory BackendChatDetail.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final user = json['user'];
    final canSend = json['canSend'];
    final cannotSendReason = json['cannotSendReason'];
    final blockedByHywork = json['blockedByHywork'];
    final iBlocked = json['iBlocked'];
    final blockedMe = json['blockedMe'];
    final warningsRaw = json['warnings'];
    final unreadCount = json['unreadCount'];
    final lastRaw = json['lastMessageAt'];

    if (id is! String ||
        !ProfileCategory.isBackendId(id) ||
        user is! Map<String, dynamic> ||
        canSend is! bool ||
        (cannotSendReason != null && cannotSendReason is! String) ||
        (blockedByHywork != null && blockedByHywork is! Map) ||
        iBlocked is! bool ||
        blockedMe is! bool ||
        (warningsRaw != null && warningsRaw is! List) ||
        unreadCount is! int ||
        unreadCount < 0 ||
        (lastRaw != null && lastRaw is! String)) {
      throw const FormatException('Invalid chat detail response.');
    }

    DateTime? lastMessageAt;
    if (lastRaw != null) {
      lastMessageAt = DateTime.tryParse(lastRaw as String);
      if (lastMessageAt == null) {
        throw const FormatException('Invalid chat detail response.');
      }
    }

    final warnings = <BackendChatWarning>[];
    if (warningsRaw is List) {
      for (final item in warningsRaw) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid chat warning response.');
        }
        warnings.add(BackendChatWarning.fromJson(item));
      }
    }

    return BackendChatDetail(
      id: id,
      user: BackendChatUser.fromJson(user),
      canSend: canSend,
      cannotSendReason: cannotSendReason as String?,
      blockedByHywork: blockedByHywork == null
          ? null
          : BackendChatHyworkBlock.fromJson(
              Map<String, dynamic>.from(blockedByHywork as Map),
            ),
      iBlocked: iBlocked,
      blockedMe: blockedMe,
      warnings: List.unmodifiable(warnings),
      unreadCount: unreadCount,
      lastMessageAt: lastMessageAt,
    );
  }
}

/// Paginated `GET /chats` payload.
class BackendChatsPage {
  const BackendChatsPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<BackendChatListItem> items;
  final int total;
  final int page;
  final int limit;

  factory BackendChatsPage.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final total = json['total'];
    final page = json['page'];
    final limit = json['limit'];
    if (itemsRaw is! List ||
        total is! int ||
        total < 0 ||
        page is! int ||
        page < 1 ||
        limit is! int ||
        limit < 1 ||
        limit > 50) {
      throw const FormatException('Invalid chats page response.');
    }
    final ids = <String>{};
    final items = <BackendChatListItem>[];
    for (final item in itemsRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid chat list item response.');
      }
      final chat = BackendChatListItem.fromJson(item);
      if (!ids.add(chat.id)) {
        throw const FormatException('Duplicate chat ID.');
      }
      items.add(chat);
    }
    return BackendChatsPage(
      items: List.unmodifiable(items),
      total: total,
      page: page,
      limit: limit,
    );
  }
}

/// Cursor page for `GET /chats/{id}/messages` (newest first).
class BackendChatMessagesPage {
  const BackendChatMessagesPage({
    required this.items,
    required this.hasMore,
    this.nextBefore,
  });

  final List<BackendChatMessage> items;
  final bool hasMore;
  final String? nextBefore;

  factory BackendChatMessagesPage.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final hasMore = json['hasMore'];
    final nextBefore = json['nextBefore'];
    if (itemsRaw is! List ||
        hasMore is! bool ||
        (nextBefore != null && nextBefore is! String)) {
      throw const FormatException('Invalid chat messages response.');
    }
    final ids = <String>{};
    final items = <BackendChatMessage>[];
    for (final item in itemsRaw) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid chat message response.');
      }
      final message = BackendChatMessage.fromJson(item);
      if (!ids.add(message.id)) {
        throw const FormatException('Duplicate chat message ID.');
      }
      items.add(message);
    }
    final cursor = nextBefore as String?;
    if (cursor != null &&
        cursor.isNotEmpty &&
        !ProfileCategory.isBackendId(cursor)) {
      throw const FormatException('Invalid chat messages response.');
    }
    return BackendChatMessagesPage(
      items: List.unmodifiable(items),
      hasMore: hasMore,
      nextBefore: cursor == null || cursor.isEmpty ? null : cursor,
    );
  }
}

/// `GET /chats/unread-count` — unread chats and messages.
class BackendChatUnreadCount {
  const BackendChatUnreadCount({required this.chats, required this.messages});

  final int chats;
  final int messages;

  factory BackendChatUnreadCount.fromJson(Map<String, dynamic> json) {
    final chats = json['chats'];
    final messages = json['messages'];
    if (chats is! int || chats < 0 || messages is! int || messages < 0) {
      throw const FormatException('Invalid chat unread-count response.');
    }
    return BackendChatUnreadCount(chats: chats, messages: messages);
  }
}

/// Confirmed `POST /chats/{id}/read` result.
class MarkChatReadResult {
  const MarkChatReadResult({required this.read});

  final int read;

  factory MarkChatReadResult.fromJson(Map<String, dynamic> json) {
    final read = json['read'];
    if (read is! int || read < 0) {
      throw const FormatException('Mark chat read was not confirmed.');
    }
    return MarkChatReadResult(read: read);
  }
}

/// Confirmed `POST /uploads?purpose=chat` result.
class BackendChatUpload {
  const BackendChatUpload({
    required this.url,
    required this.purpose,
    this.thumbnailUrl,
    this.width,
    this.height,
    this.size,
    this.contentType,
  });

  final String url;
  final String? thumbnailUrl;
  final String purpose;
  final int? width;
  final int? height;
  final int? size;
  final String? contentType;

  factory BackendChatUpload.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    final thumbnailUrl = json['thumbnailUrl'];
    final purpose = json['purpose'];
    final width = json['width'];
    final height = json['height'];
    final size = json['size'];
    final contentType = json['contentType'];
    final uri = url is String ? Uri.tryParse(url) : null;
    if (uri == null ||
        uri.host.isEmpty ||
        !const ['http', 'https'].contains(uri.scheme) ||
        purpose != 'chat' ||
        (thumbnailUrl != null && thumbnailUrl is! String) ||
        (width != null && width is! int) ||
        (height != null && height is! int) ||
        (size != null && size is! int) ||
        (contentType != null && contentType is! String)) {
      throw const FormatException('Chat photo upload was not confirmed.');
    }
    return BackendChatUpload(
      url: uri.toString(),
      thumbnailUrl: thumbnailUrl as String?,
      purpose: purpose as String,
      width: width as int?,
      height: height as int?,
      size: size as int?,
      contentType: contentType as String?,
    );
  }
}
