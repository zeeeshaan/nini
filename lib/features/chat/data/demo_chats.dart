import 'package:nini/features/chat/domain/models/chat_conversation.dart';

List<ChatConversation> createDemoConversations() {
  final now = DateTime.now();

  return [
    ChatConversation(
      id: 'support',
      name: 'Contact support',
      lastMessage: 'How can we help you today?',
      lastMessageAt: now.subtract(const Duration(minutes: 2)),
      unreadCount: 1,
      isSupport: true,
    ),
    ChatConversation(
      id: 'user_1',
      name: 'Obid Ematy',
      lastMessage: 'Thank you for your message.',
      lastMessageAt: now.subtract(const Duration(minutes: 8)),
    ),
    ChatConversation(
      id: 'user_2',
      name: 'PipeMaster',
      lastMessage: 'I will send you the details.',
      lastMessageAt: now.subtract(const Duration(minutes: 15)),
    ),
    ChatConversation(
      id: 'user_3',
      name: 'Sarah Ahmed',
      lastMessage: 'Is this product still available?',
      lastMessageAt: now.subtract(const Duration(minutes: 24)),
    ),
    ChatConversation(
      id: 'user_4',
      name: 'Alex Morgan',
      lastMessage: 'Can we discuss the price?',
      lastMessageAt: now.subtract(const Duration(minutes: 35)),
    ),
    ChatConversation(
      id: 'user_5',
      name: 'David Wilson',
      lastMessage: 'Sounds good, thank you!',
      lastMessageAt: now.subtract(const Duration(hours: 1)),
    ),
    ChatConversation(
      id: 'user_6',
      name: 'Nina Parker',
      lastMessage: 'I will get back to you soon.',
      lastMessageAt: now.subtract(const Duration(hours: 2)),
    ),
    ChatConversation(
      id: 'user_7',
      name: 'James Carter',
      lastMessage: 'Please share more information.',
      lastMessageAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}
