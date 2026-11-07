import 'package:flutter/material.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/shared/models/post/post_seller.dart';

/// Shares one session conversation per seller across profile and post entries.
void openSellerConversation(BuildContext context, PostSeller seller) {
  final conversation = InMemoryChatRepository.instance.openConversation(
    ChatConversation(
      id: 'seller-${seller.id}',
      name: seller.name,
      avatarAsset: seller.avatarAsset,
      lastMessage: '',
      lastMessageAt: DateTime.now(),
    ),
  );
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversation: conversation,
        subtitle: seller.location.isEmpty ? null : seller.location,
      ),
    ),
  );
}
