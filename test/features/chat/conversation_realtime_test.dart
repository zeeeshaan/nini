import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/network/realtime/realtime_connection_state.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/core/network/realtime/realtime_socket_transport.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _FixedRandom implements math.Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  Map<String, dynamic>? detailResponse;
  Map<String, dynamic>? messagesResponse;
  Map<String, dynamic>? sendResponse;
  Map<String, dynamic>? unreadResponse;
  Map<String, dynamic>? listResponse;
  Object? messagesError;
  Object? unreadError;
  int messageCalls = 0;
  int unreadCalls = 0;
  int listCalls = 0;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    if (endpoint.contains('unread-count')) {
      unreadCalls++;
      if (unreadError != null) throw unreadError!;
      return Map<String, dynamic>.from(
        unreadResponse ??
            {
              'success': true,
              'data': {'chats': 0, 'messages': 0},
            },
      );
    }
    if (endpoint.contains('/messages')) {
      messageCalls++;
      if (messagesError != null) throw messagesError!;
      return Map<String, dynamic>.from(
        messagesResponse ??
            {
              'success': true,
              'data': {
                'items': <dynamic>[],
                'hasMore': false,
                'nextBefore': null,
              },
            },
      );
    }
    if (endpoint == 'chats' || endpoint.startsWith('chats?')) {
      listCalls++;
      return Map<String, dynamic>.from(
        listResponse ??
            {
              'success': true,
              'data': {
                'items': <dynamic>[],
                'page': 1,
                'limit': 20,
                'total': 0,
              },
            },
      );
    }
    return Map<String, dynamic>.from(
      detailResponse ?? {'success': true, 'data': _detail()},
    );
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    posts.add(endpoint);
    if (endpoint.endsWith('/read')) {
      return {
        'success': true,
        'data': {'read': 1},
      };
    }
    return Map<String, dynamic>.from(
      sendResponse ??
          {
            'success': true,
            'data': _message(
              id: messageId,
              text: data?['text'] as String? ?? '',
              isMine: true,
            ),
          },
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
    Map<String, dynamic>? data,
  }) async {
    return {'success': true, 'data': <String, dynamic>{}};
  }
}

const chatId = '11111111-1111-4111-8111-111111111111';
const otherChatId = 'aaaaaaaa-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';
const messageId = '33333333-3333-4333-8333-333333333333';
const newerId = '44444444-4444-4444-8444-444444444444';
const meId = '66666666-6666-4666-8666-666666666666';
const deletedId = '77777777-7777-4777-8777-777777777777';

Map<String, dynamic> _detail() => {
  'id': chatId,
  'user': {
    'id': userId,
    'name': 'Peer',
    'username': 'peer',
    'avatarUrl': null,
    'verified': false,
  },
  'canSend': true,
  'cannotSendReason': null,
  'blockedByHywork': null,
  'iBlocked': false,
  'blockedMe': false,
  'warnings': <dynamic>[],
  'unreadCount': 0,
  'lastMessageAt': '2026-11-20T10:00:00.000Z',
};

Map<String, dynamic> _message({
  required String id,
  required String text,
  bool isMine = false,
  bool deleted = false,
  String? readAt,
  String createdAt = '2026-11-20T10:00:00.000Z',
  String? conversationId,
}) {
  return {
    'id': id,
    'conversationId': conversationId ?? chatId,
    'senderId': isMine ? meId : userId,
    'isMine': isMine,
    'type': 'text',
    'text': text,
    'imageUrl': null,
    'deleted': deleted,
    'deletedBy': deleted ? 'sender' : null,
    'readAt': readAt,
    'createdAt': createdAt,
  };
}

Map<String, dynamic> _listItem({
  required String id,
  String lastText = 'hi',
  int unread = 0,
}) => {
  'id': id,
  'user': {
    'id': userId,
    'name': 'Peer',
    'username': 'peer',
    'avatarUrl': null,
    'verified': false,
  },
  'lastMessage': _message(id: messageId, text: lastText),
  'lastMessageAt': '2026-11-20T10:00:00.000Z',
  'unreadCount': unread,
  'canSend': true,
  'blockedByHywork': false,
  'iBlocked': false,
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRealtimeSocketTransport transport;
  late RealtimeSocketClient realtime;
  late List<FakeRealtimeSocketTransport> transports;

  Future<void> readySocket() async {
    transports = <FakeRealtimeSocketTransport>[];
    realtime = RealtimeSocketClient(
      tokenStore: _Tokens(),
      isCurrentAccount: () => true,
      accountRevision: 1,
      userId: meId,
      apiBaseUrl: 'http://example.test/api',
      transportFactory: () {
        transport = FakeRealtimeSocketTransport();
        transports.add(transport);
        return transport;
      },
      maxReconnectAttempts: 3,
      random: _FixedRandom(),
    );
    await realtime.connect();
    transport.completeConnect();
    transport.push('ready', {
      'userId': meId,
      'unread': {'notifications': 0, 'chats': 2, 'chatMessages': 5},
    });
    await Future<void>.delayed(Duration.zero);
    expect(realtime.state, RealtimeConnectionState.ready);
  }

  ConversationCubit conversationCubit(
    _Api api, {
    Duration pollInterval = const Duration(seconds: 4),
    Duration peerTypingTimeout = const Duration(seconds: 5),
  }) {
    var current = true;
    return ConversationCubit(
      conversationId: chatId,
      repository: ApiChatsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => current,
        onUnauthorized: () async {
          current = false;
        },
      ),
      isCurrentAccount: () => current,
      currentUserId: () => meId,
      realtime: realtime,
      pollInterval: pollInterval,
      detailsInterval: const Duration(hours: 1),
      peerTypingTimeout: peerTypingTimeout,
    );
  }

  tearDown(() async {
    await realtime.dispose();
  });

  setUp(() async {
    await readySocket();
  });

  test('incoming socket message appears immediately and dedupes', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'old')],
          'hasMore': true,
          'nextBefore': messageId,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    // Socket ready + load reconciles → message polling paused.
    expect(cubit.isSocketReadyForPolling, isTrue);
    expect(cubit.isPollingScheduled, isFalse);

    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(
        id: newerId,
        text: 'live',
        createdAt: '2026-11-20T11:00:00.000Z',
      ),
      'unread': 1,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages.map((m) => m.id), [messageId, newerId]);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.nextBefore, messageId);

    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(
        id: newerId,
        text: 'live',
        createdAt: '2026-11-20T11:00:00.000Z',
      ),
      'unread': 1,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages.where((m) => m.id == newerId), hasLength(1));
    await cubit.close();
  });

  test('REST before socket and socket before REST reconcile by id', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {'items': <dynamic>[], 'hasMore': false, 'nextBefore': null},
      }
      ..sendResponse = {
        'success': true,
        'data': _message(id: newerId, text: 'mine', isMine: true),
      };
    final cubit = conversationCubit(api);
    await cubit.load();
    cubit.setLifecycle(visible: true, foreground: true);

    // Socket first
    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(id: newerId, text: 'mine', isMine: true),
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages.map((m) => m.id), [newerId]);

    final sent = await cubit.sendMessage('mine');
    expect(sent, isTrue);
    expect(cubit.state.messages.where((m) => m.id == newerId), hasLength(1));

    // REST-first path for another id
    api.sendResponse = {
      'success': true,
      'data': _message(
        id: messageId,
        text: 'second',
        isMine: true,
        createdAt: '2026-11-20T11:01:00.000Z',
      ),
    };
    await cubit.sendMessage('second');
    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(
        id: messageId,
        text: 'second',
        isMine: true,
        createdAt: '2026-11-20T11:01:00.000Z',
      ),
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.messages.where((m) => m.id == messageId), hasLength(1));
    await cubit.close();
  });

  test('message deletion tombstone blocks stale REST restore', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(id: deletedId, text: 'bye'),
            _message(id: messageId, text: 'hi'),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();

    transport.push('chat:message_deleted', {
      'conversationId': chatId,
      'messageId': deletedId,
    });
    await Future<void>.delayed(Duration.zero);
    final deleted = cubit.state.messages.firstWhere((m) => m.id == deletedId);
    expect(deleted.deleted, isTrue);
    expect(deleted.text, isEmpty);
    expect(cubit.state.visibleMessages.any((m) => m.id == deletedId), isFalse);

    api.messagesResponse = {
      'success': true,
      'data': {
        'items': [
          _message(id: deletedId, text: 'bye'),
          _message(id: messageId, text: 'hi'),
        ],
        'hasMore': false,
        'nextBefore': null,
      },
    };
    await cubit.reconcileSilently();
    final still = cubit.state.messages.firstWhere((m) => m.id == deletedId);
    expect(still.deleted, isTrue);
    expect(cubit.state.visibleMessages.any((m) => m.id == deletedId), isFalse);
    expect(still.text, isEmpty);
    await cubit.close();
  });

  test('read receipts apply monotonically and ignore own readBy', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: newerId,
              text: 'later',
              isMine: true,
              createdAt: '2026-11-20T11:00:00.000Z',
            ),
            _message(
              id: messageId,
              text: 'earlier',
              isMine: true,
              createdAt: '2026-11-20T10:00:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();

    transport.push('chat:read', {
      'conversationId': chatId,
      'readBy': meId,
      'readAt': '2026-11-20T12:00:00.000Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.messages.every(
        (m) => m.deliveryStatus == ChatDeliveryStatus.sent,
      ),
      isTrue,
    );

    transport.push('chat:read', {
      'conversationId': chatId,
      'readBy': userId,
      'readAt': '2026-11-20T10:30:00.000Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.messages.firstWhere((m) => m.id == messageId).deliveryStatus,
      ChatDeliveryStatus.read,
    );
    expect(
      cubit.state.messages.firstWhere((m) => m.id == newerId).deliveryStatus,
      ChatDeliveryStatus.sent,
    );

    transport.push('chat:read', {
      'conversationId': chatId,
      'readBy': userId,
      'readAt': '2026-11-20T09:00:00.000Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.messages.firstWhere((m) => m.id == newerId).deliveryStatus,
      ChatDeliveryStatus.sent,
    );

    transport.push('chat:read', {
      'conversationId': chatId,
      'readBy': userId,
      'readAt': '2026-11-20T11:30:00.000Z',
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.messages.every(
        (m) => m.deliveryStatus == ChatDeliveryStatus.read,
      ),
      isTrue,
    );
    await cubit.close();
  });

  test('typing expiry, own events ignored, cleanup on dispose', () {
    fakeAsync((async) {
      final api = _Api();
      final cubit = conversationCubit(
        api,
        peerTypingTimeout: const Duration(seconds: 5),
      );
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();

      // Outgoing throttle is covered by realtime_socket_client_test; here we
      // only assert the cubit forwards a typing signal while ready.
      cubit.setComposerTyping(true);
      expect(
        transport.emitted.where((e) => e.key == RealtimeEventName.chatTyping),
        isNotEmpty,
      );

      transport.push('chat:typing', {
        'conversationId': chatId,
        'userId': userId,
        'typing': true,
      });
      async.flushMicrotasks();
      expect(cubit.state.peerTyping, isTrue);

      transport.push('chat:typing', {
        'conversationId': chatId,
        'userId': meId,
        'typing': true,
      });
      async.flushMicrotasks();
      expect(cubit.state.peerTyping, isTrue);

      async.elapse(const Duration(seconds: 5));
      async.flushMicrotasks();
      expect(cubit.state.peerTyping, isFalse);

      transport.push('chat:typing', {
        'conversationId': otherChatId,
        'userId': userId,
        'typing': true,
      });
      async.flushMicrotasks();
      expect(cubit.state.peerTyping, isFalse);

      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('disconnect resumes polling; ready after reconcile pauses it', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'hi')],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isPollingScheduled, isFalse);

    transport.completeDisconnect();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isSocketReadyForPolling, isFalse);
    expect(cubit.isPollingScheduled, isTrue);

    final before = api.messageCalls;
    await cubit.debugPollOnce();
    expect(api.messageCalls, greaterThan(before));

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(transports.length, greaterThanOrEqualTo(2));
    final next = transports.last;
    next.completeConnect();
    next.push('ready', {
      'userId': meId,
      'unread': {'notifications': 0, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(cubit.isSocketReadyForPolling, isTrue);
    expect(cubit.isPollingScheduled, isFalse);
    await cubit.close();
  });

  test('events during recovery merge without clearing history', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'old')],
          'hasMore': true,
          'nextBefore': messageId,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();
    cubit.setLifecycle(visible: true, foreground: true);

    transport.completeDisconnect();
    await Future<void>.delayed(Duration.zero);

    // Trigger reconnect recovery path
    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final next = transports.last;
    next.completeConnect();
    next.push('ready', {
      'userId': meId,
      'unread': {'notifications': 0, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(Duration.zero);

    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(
        id: newerId,
        text: 'during recovery',
        createdAt: '2026-11-20T12:00:00.000Z',
      ),
    });
    await Future<void>.delayed(Duration.zero);

    expect(
      cubit.state.messages.map((m) => m.id),
      containsAll([messageId, newerId]),
    );
    expect(cubit.state.nextBefore, messageId);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
  });

  test('failed recovery keeps polling fallback', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'hi')],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = conversationCubit(api);
    await cubit.load();
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isPollingScheduled, isFalse);

    transport.completeDisconnect();
    await Future<void>.delayed(Duration.zero);
    expect(cubit.isPollingScheduled, isTrue);

    api.messagesError = DioException(
      requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(transports.length, greaterThanOrEqualTo(2));
    final next = transports.last;
    next.completeConnect();
    next.push('ready', {
      'userId': meId,
      'unread': {'notifications': 0, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));
    // Recovery silent sync fails → keep message polling.
    expect(cubit.isSocketReadyForPolling, isTrue);
    expect(cubit.isPollingScheduled, isTrue);
    await cubit.close();
  });

  test('inbox applies live preview and refreshes unknown chats', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_listItem(id: chatId, lastText: 'old', unread: 1)],
          'page': 1,
          'limit': 20,
          'total': 1,
        },
      };
    final inbox = ChatInboxCubit(
      ApiChatsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => true,
      realtime: realtime,
    );
    await inbox.load();
    expect(inbox.state.conversations.single.lastMessage, 'old');

    transport.push('chat:message', {
      'conversationId': chatId,
      'message': _message(
        id: newerId,
        text: 'fresh',
        createdAt: '2026-11-20T12:00:00.000Z',
      ),
      'unread': 2,
    });
    await Future<void>.delayed(Duration.zero);
    expect(inbox.state.conversations.single.lastMessage, 'fresh');
    expect(inbox.state.conversations.single.unreadCount, 2);

    final listsBefore = api.listCalls;
    transport.push('chat:message', {
      'conversationId': otherChatId,
      'message': _message(
        id: newerId,
        text: 'other',
        conversationId: otherChatId,
      ),
    });
    await Future<void>.delayed(Duration.zero);
    expect(api.listCalls, greaterThan(listsBefore));
    await inbox.close();
  });

  test('unread ready badges and live events refresh REST count', () async {
    final api = _Api()
      ..unreadResponse = {
        'success': true,
        'data': {'chats': 9, 'messages': 20},
      };
    final unread = ChatUnreadCubit(
      ApiChatsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => true,
      realtime: realtime,
    );
    // Drain the constructor refresh before applying socket badges.
    await unread.refresh();
    expect(unread.state.chats, 9);

    unread.applyReadyUnread(chats: 3, chatMessages: 7);
    expect(unread.state.chats, 3);
    expect(unread.state.messages, 7);
    expect(unread.state.badgeCount, 3);

    // Invalidate in-flight REST: ready revision must win until next refresh.
    api.unreadResponse = {
      'success': true,
      'data': {'chats': 5, 'messages': 11},
    };
    final refreshed = unread.refresh();
    await refreshed;
    expect(unread.state.chats, 5);
    expect(unread.state.badgeCount, 5);
    await unread.close();
  });

  test(
    'stale account events ignored and dispose cancels subscriptions',
    () async {
      var current = true;
      final api = _Api();
      final cubit = ConversationCubit(
        conversationId: chatId,
        repository: ApiChatsRepository(
          api,
          _Tokens(),
          isCurrentAccount: () => current,
          onUnauthorized: () async {
            current = false;
          },
        ),
        isCurrentAccount: () => current,
        currentUserId: () => meId,
        realtime: realtime,
        detailsInterval: const Duration(hours: 1),
      );
      await cubit.load();
      current = false;
      transport.push('chat:message', {
        'conversationId': chatId,
        'message': _message(id: newerId, text: 'nope'),
      });
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.messages.any((m) => m.id == newerId), isFalse);
      await cubit.close();
    },
  );
}
