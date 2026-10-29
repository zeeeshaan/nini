import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';

List<ChatConversation> createDemoConversations() {
  final now = DateTime.now();

  return [
    ChatConversation(
      id: 'support',
      name: AppStrings.chatSupportName,
      lastMessage: AppStrings.demoSupportPreview,
      lastMessageAt: now.subtract(const Duration(minutes: 2)),
      unreadCount: 1,
      isSupport: true,
    ),
    ChatConversation(
      id: 'user_1',
      name: AppStrings.demoObidName,
      lastMessage: AppStrings.demoThanksPreview,
      lastMessageAt: now.subtract(const Duration(minutes: 8)),
    ),
    ChatConversation(
      id: 'user_2',
      name: AppStrings.authorName,
      lastMessage: AppStrings.demoDetailsPreview,
      lastMessageAt: now.subtract(const Duration(minutes: 15)),
    ),
    ChatConversation(
      id: 'user_3',
      name: AppStrings.demoSarahName,
      lastMessage: AppStrings.demoAvailabilityPreview,
      lastMessageAt: now.subtract(const Duration(minutes: 24)),
    ),
    ChatConversation(
      id: 'user_4',
      name: AppStrings.demoAlexName,
      lastMessage: AppStrings.demoPricePreview,
      lastMessageAt: now.subtract(const Duration(minutes: 35)),
    ),
    ChatConversation(
      id: 'user_5',
      name: AppStrings.demoDavidName,
      lastMessage: AppStrings.demoSoundsGoodPreview,
      lastMessageAt: now.subtract(const Duration(hours: 1)),
    ),
    ChatConversation(
      id: 'user_6',
      name: AppStrings.demoNinaName,
      lastMessage: AppStrings.demoSoonPreview,
      lastMessageAt: now.subtract(const Duration(hours: 2)),
    ),
    ChatConversation(
      id: 'user_7',
      name: AppStrings.demoJamesName,
      lastMessage: AppStrings.demoMoreInfoPreview,
      lastMessageAt: now.subtract(const Duration(hours: 3)),
    ),
  ];
}
