class ChatConversation {
  const ChatConversation({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageAt,
    this.unreadCount = 0,
    this.isSupport = false,
    this.avatarAsset,
    this.isBlocked = false,
    this.peerUserId,
    this.canSend = true,
    this.cannotSendReason,
  });

  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isSupport;
  final String? avatarAsset;
  final bool isBlocked;
  final String? peerUserId;
  final bool canSend;
  final String? cannotSendReason;

  ChatConversation copyWith({
    int? unreadCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isBlocked,
    String? name,
    String? avatarAsset,
    String? peerUserId,
    bool? canSend,
    String? cannotSendReason,
    bool clearCannotSendReason = false,
  }) {
    return ChatConversation(
      id: id,
      name: name ?? this.name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isSupport: isSupport,
      avatarAsset: avatarAsset ?? this.avatarAsset,
      isBlocked: isBlocked ?? this.isBlocked,
      peerUserId: peerUserId ?? this.peerUserId,
      canSend: canSend ?? this.canSend,
      cannotSendReason: clearCannotSendReason
          ? null
          : (cannotSendReason ?? this.cannotSendReason),
    );
  }
}
