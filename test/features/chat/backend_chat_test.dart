import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';

void main() {
  const chatId = '11111111-1111-4111-8111-111111111111';
  const userId = '22222222-2222-4222-8222-222222222222';
  const messageId = '33333333-3333-4333-8333-333333333333';

  Map<String, dynamic> message({
    String id = messageId,
    String type = 'text',
    String? text = 'Hello',
    String? imageUrl,
    bool deleted = false,
    String? deletedBy,
  }) => {
    'id': id,
    'conversationId': chatId,
    'senderId': userId,
    'isMine': true,
    'type': type,
    'text': text,
    'imageUrl': imageUrl,
    'deleted': deleted,
    'deletedBy': deletedBy,
    'readAt': null,
    'createdAt': '2026-11-20T09:00:00.000Z',
  };

  Map<String, dynamic> user() => {
    'id': userId,
    'name': 'Sara',
    'username': 'sara',
    'avatarUrl': null,
    'verified': true,
  };

  test('parses chat detail with warnings and known cannotSendReason', () {
    final detail = BackendChatDetail.fromJson({
      'id': chatId,
      'user': user(),
      'canSend': false,
      'cannotSendReason': ChatCannotSendReason.youBlockedUser,
      'blockedByHywork': null,
      'iBlocked': true,
      'blockedMe': false,
      'warnings': [
        {
          'id': '44444444-4444-4444-8444-444444444444',
          'message': 'Be respectful.',
          'createdAt': '2026-11-19T09:00:00.000Z',
        },
      ],
      'unreadCount': 2,
      'lastMessageAt': '2026-11-20T09:00:00.000Z',
    });
    expect(detail.id, chatId);
    expect(detail.user.id, userId);
    expect(detail.canSend, isFalse);
    expect(detail.cannotSendReason, ChatCannotSendReason.youBlockedUser);
    expect(detail.hasKnownCannotSendReason, isTrue);
    expect(detail.warnings, hasLength(1));
    expect(detail.warnings.single.message, 'Be respectful.');
  });

  test('preserves unknown cannotSendReason without failing', () {
    final detail = BackendChatDetail.fromJson({
      'id': chatId,
      'user': user(),
      'canSend': false,
      'cannotSendReason': 'policy_hold',
      'iBlocked': false,
      'blockedMe': false,
      'warnings': <dynamic>[],
      'unreadCount': 0,
    });
    expect(detail.cannotSendReason, 'policy_hold');
    expect(detail.hasKnownCannotSendReason, isFalse);
  });

  test('parses text, image and soft-deleted messages', () {
    final text = BackendChatMessage.fromJson(message());
    expect(text.type, BackendChatMessageType.text);
    expect(text.text, 'Hello');

    final image = BackendChatMessage.fromJson(
      message(
        type: 'image',
        text: null,
        imageUrl: 'https://cdn.example/chat.webp',
      ),
    );
    expect(image.type, BackendChatMessageType.image);
    expect(image.imageUrl, contains('chat.webp'));

    final deleted = BackendChatMessage.fromJson(
      message(deleted: true, deletedBy: 'sender', text: null),
    );
    expect(deleted.deleted, isTrue);
    expect(deleted.deletedBy, ChatMessageDeletedBy.sender);
  });

  test('parses message cursor page newest-first metadata', () {
    final page = BackendChatMessagesPage.fromJson({
      'items': [message()],
      'hasMore': true,
      'nextBefore': messageId,
    });
    expect(page.hasMore, isTrue);
    expect(page.nextBefore, messageId);
    expect(page.items.single.conversationId, chatId);
  });

  test('parses unread chats and messages counts', () {
    final count = BackendChatUnreadCount.fromJson({'chats': 2, 'messages': 5});
    expect(count.chats, 2);
    expect(count.messages, 5);
  });

  test('rejects fabricated zero-style unread payloads', () {
    expect(
      () => BackendChatUnreadCount.fromJson({'chats': 1}),
      throwsFormatException,
    );
  });

  test('keeps chat, user and message ids separate', () {
    final item = BackendChatListItem.fromJson({
      'id': chatId,
      'user': user(),
      'lastMessage': message(),
      'lastMessageAt': '2026-11-20T09:00:00.000Z',
      'unreadCount': 1,
      'canSend': true,
      'blockedByHywork': false,
      'iBlocked': false,
    });
    expect(item.id, isNot(item.user.id));
    expect(item.id, isNot(item.lastMessage!.id));
    expect(item.user.id, isNot(item.lastMessage!.id));
  });
}
