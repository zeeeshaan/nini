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
  });

  final String id;
  final String name;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;
  final bool isSupport;
  final String? avatarAsset;
  final bool isBlocked;

  ChatConversation copyWith({
    int? unreadCount,
    String? lastMessage,
    DateTime? lastMessageAt,
    bool? isBlocked,
  }) {
    return ChatConversation(
      id: id,
      name: name,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isSupport: isSupport,
      avatarAsset: avatarAsset,
      isBlocked: isBlocked ?? this.isBlocked,
    );
  }
}
