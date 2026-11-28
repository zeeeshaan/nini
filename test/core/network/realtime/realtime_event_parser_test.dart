import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/realtime/realtime_event_parser.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';

const _chatId = '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99';
const _userId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f';
const _messageId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20';
const _notificationId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e21';

Map<String, dynamic> _message() => {
  'id': _messageId,
  'conversationId': _chatId,
  'senderId': _userId,
  'isMine': false,
  'type': 'text',
  'text': 'Hello',
  'imageUrl': null,
  'deleted': false,
  'deletedBy': null,
  'readAt': null,
  'createdAt': '2026-11-20T09:00:00.000Z',
};

Map<String, dynamic> _notification() => {
  'id': _notificationId,
  'type': 'post.approved',
  'title': 'Post approved',
  'body': 'Live now.',
  'titleFa': 'تأیید شد',
  'bodyFa': 'منتشر شد.',
  'target': {'type': 'post', 'id': _chatId},
  'data': <String, dynamic>{},
  'isRead': false,
  'readAt': null,
  'createdAt': '2026-11-20T09:00:00.000Z',
};

void main() {
  test('parses ready badges', () {
    final event = RealtimeEventParser.parse('ready', {
      'userId': _userId,
      'unread': {'notifications': 2, 'chats': 1, 'chatMessages': 4},
    });
    expect(event, isA<RealtimeReady>());
    final ready = event as RealtimeReady;
    expect(ready.userId, _userId);
    expect(ready.unread.notifications, 2);
    expect(ready.unread.chats, 1);
    expect(ready.unread.chatMessages, 4);
  });

  test('parses chat:message with BackendChatMessage', () {
    final event = RealtimeEventParser.parse('chat:message', {
      'conversationId': _chatId,
      'message': _message(),
      'unread': 3,
    });
    expect(event, isA<RealtimeChatMessage>());
    final message = event as RealtimeChatMessage;
    expect(message.conversationId, _chatId);
    expect(message.message.text, 'Hello');
    expect(message.unread, 3);
  });

  test('parses chat:read, typing, deleted and unread', () {
    expect(
      RealtimeEventParser.parse('chat:read', {
        'conversationId': _chatId,
        'readBy': _userId,
        'readAt': '2026-11-20T09:01:00.000Z',
      }),
      isA<RealtimeChatRead>(),
    );
    expect(
      RealtimeEventParser.parse('chat:typing', {
        'conversationId': _chatId,
        'userId': _userId,
        'typing': true,
      }),
      isA<RealtimeChatTyping>(),
    );
    expect(
      RealtimeEventParser.parse('chat:message_deleted', {
        'conversationId': _chatId,
        'messageId': _messageId,
      }),
      isA<RealtimeChatMessageDeleted>(),
    );
    expect(
      RealtimeEventParser.parse('chat:unread', {
        'conversationId': _chatId,
        'unread': 0,
      }),
      isA<RealtimeChatUnread>(),
    );
  });

  test('parses notification:new and notification:read', () {
    final created = RealtimeEventParser.parse('notification:new', {
      'notification': _notification(),
      'unreadCount': 5,
    });
    expect(created, isA<RealtimeNotificationNew>());
    expect((created as RealtimeNotificationNew).unreadCount, 5);

    final read = RealtimeEventParser.parse('notification:read', {
      'ids': [_notificationId],
      'all': false,
      'unreadCount': 4,
    });
    expect(read, isA<RealtimeNotificationRead>());
    expect((read as RealtimeNotificationRead).ids, [_notificationId]);
  });

  test('unknown events are preserved without throwing', () {
    final event = RealtimeEventParser.parse('future:event', {'x': 1});
    expect(event, isA<RealtimeUnknownEvent>());
    expect((event as RealtimeUnknownEvent).name, 'future:event');
  });

  test('malformed payloads become RealtimeMalformedEvent', () {
    final event = RealtimeEventParser.parse('ready', {'userId': 'bad'});
    expect(event, isA<RealtimeMalformedEvent>());
  });

  test('parses documented connect_error auth codes', () {
    expect(
      RealtimeEventParser.parseConnectError('not_logged_in')?.code,
      'not_logged_in',
    );
    expect(
      RealtimeEventParser.parseConnectError({'message': 'session_expired'})
          ?.code,
      'session_expired',
    );
    expect(
      RealtimeEventParser.parseConnectError('account_unavailable')?.code,
      'account_unavailable',
    );
    expect(RealtimeEventParser.parseConnectError('timeout'), isNull);
  });
}
