import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/data/in_memory_chat_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/domain/backend_chat_mapper.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/presentation/helpers/chat_message_labels.dart';
import 'package:hywork/features/chat/presentation/widgets/messages/chat_message_bubble.dart';

void main() {
  test('production in-memory chat store starts empty', () {
    final store = InMemoryChatRepository.empty();
    expect(store.conversations, isEmpty);
    expect(store.getMessages('any'), isEmpty);
  });

  test('deleted messages never produce placeholder preview text', () {
    final deleted = ChatMessage(
      id: '33333333-3333-4333-8333-333333333333',
      conversationId: '11111111-1111-4111-8111-111111111111',
      text: '',
      sentAt: DateTime.utc(2026, 11, 20),
      isMine: true,
      deleted: true,
    );
    expect(chatMessagePreview(deleted), AppStrings.noMessages);
    expect(
      backendChatMessagePreview(
        BackendChatMessage(
          id: deleted.id,
          conversationId: deleted.conversationId,
          isMine: true,
          type: BackendChatMessageType.text,
          deleted: true,
          createdAt: deleted.sentAt,
          text: null,
        ),
      ),
      AppStrings.noMessages,
    );
  });

  testWidgets('deleted message bubble renders no visible content or spacing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ChatMessageBubble(
            message: ChatMessage(
              id: '33333333-3333-4333-8333-333333333333',
              conversationId: '11111111-1111-4111-8111-111111111111',
              text: 'gone',
              sentAt: DateTime.utc(2026, 11, 20, 10, 30),
              isMine: true,
              deleted: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('gone'), findsNothing);
    expect(find.textContaining('10'), findsNothing);
    expect(tester.getSize(find.byType(ChatMessageBubble)), Size.zero);
  });
}
