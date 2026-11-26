import 'package:dio/dio.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  Map<String, dynamic>? detailResponse;
  Map<String, dynamic>? messagesResponse;
  Object? messagesError;
  int messageCalls = 0;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
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
    return {
      'success': true,
      'data': _message(id: messageId, text: data?['text'] as String? ?? ''),
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    return {'success': true, 'data': <String, dynamic>{}};
  }
}

const chatId = '11111111-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';
const messageId = '33333333-3333-4333-8333-333333333333';
const newerId = '44444444-4444-4444-8444-444444444444';
const gapId = '55555555-5555-4555-8555-555555555555';
const meId = '66666666-6666-4666-8666-666666666666';

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
  String createdAt = '2026-11-20T10:00:00.000Z',
}) {
  return {
    'id': id,
    'conversationId': chatId,
    'senderId': isMine ? meId : userId,
    'isMine': isMine,
    'type': 'text',
    'text': text,
    'imageUrl': null,
    'deleted': deleted,
    'deletedBy': deleted ? 'sender' : null,
    'readAt': null,
    'createdAt': createdAt,
  };
}

ConversationCubit _cubit(
  _Api api, {
  Duration pollInterval = const Duration(seconds: 4),
  bool Function()? isCurrentAccount,
}) {
  var current = true;
  return ConversationCubit(
    conversationId: chatId,
    repository: ApiChatsRepository(
      api,
      _Tokens(),
      isCurrentAccount: isCurrentAccount ?? () => current,
      onUnauthorized: () async {
        current = false;
      },
    ),
    isCurrentAccount: isCurrentAccount ?? () => current,
    currentUserId: () => meId,
    pollInterval: pollInterval,
    detailsInterval: const Duration(hours: 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('polling starts when active and stops when hidden', () {
    fakeAsync((async) {
      final api = _Api()
        ..messagesResponse = {
          'success': true,
          'data': {
            'items': [_message(id: messageId, text: 'hi')],
            'hasMore': false,
            'nextBefore': null,
          },
        };
      final cubit = _cubit(api);
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isTrue);

      final before = api.messageCalls;
      async.elapse(const Duration(seconds: 4));
      async.flushMicrotasks();
      expect(api.messageCalls, greaterThan(before));

      cubit.setLifecycle(visible: false, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isFalse);
      final paused = api.messageCalls;
      async.elapse(const Duration(seconds: 12));
      async.flushMicrotasks();
      expect(api.messageCalls, paused);

      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('polling pauses in background and resumes with immediate refresh', () {
    fakeAsync((async) {
      final api = _Api()
        ..messagesResponse = {
          'success': true,
          'data': {
            'items': [_message(id: messageId, text: 'hi')],
            'hasMore': false,
            'nextBefore': null,
          },
        };
      final cubit = _cubit(api);
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();

      cubit.setLifecycle(visible: true, foreground: false);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isFalse);
      final paused = api.messageCalls;

      api.messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: newerId,
              text: 'later',
              createdAt: '2026-11-20T11:00:00.000Z',
            ),
            _message(id: messageId, text: 'hi'),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(api.messageCalls, greaterThan(paused));
      expect(cubit.state.messages.map((m) => m.id), [messageId, newerId]);
      expect(cubit.isPollingScheduled, isTrue);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('no duplicate timers and no overlapping poll requests', () {
    fakeAsync((async) {
      final api = _Api();
      final cubit = _cubit(api);
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isTrue);

      // Overlapping silent sync coalesces on one in-flight future.
      final first = cubit.debugPollOnce();
      final second = cubit.debugPollOnce();
      expect(identical(first, second), isTrue);
      async.flushMicrotasks();
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test(
    'silent poll merges incoming messages and preserves older cursor',
    () async {
      final api = _Api()
        ..messagesResponse = {
          'success': true,
          'data': {
            'items': [
              _message(
                id: messageId,
                text: 'old',
                createdAt: '2026-11-20T10:00:00.000Z',
              ),
            ],
            'hasMore': true,
            'nextBefore': messageId,
          },
        };
      final cubit = _cubit(api, pollInterval: const Duration(hours: 1));
      cubit.setLifecycle(visible: true, foreground: true);
      await Future<void>.delayed(Duration.zero);
      await cubit.load();
      expect(cubit.state.nextBefore, messageId);
      expect(cubit.state.hasMore, isTrue);

      api.messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: newerId,
              text: 'new',
              createdAt: '2026-11-20T10:05:00.000Z',
            ),
            _message(
              id: messageId,
              text: 'old',
              createdAt: '2026-11-20T10:00:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
      await cubit.debugPollOnce();
      expect(cubit.state.messages.map((m) => m.id), [messageId, newerId]);
      expect(cubit.state.hasMore, isTrue);
      expect(cubit.state.nextBefore, messageId);
      await cubit.close();
    },
  );

  test('gap fill walks before cursor so messages are not lost', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: messageId,
              text: 'seed',
              createdAt: '2026-11-20T09:00:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api, pollInterval: const Duration(hours: 1));
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    await cubit.close();

    final gapApi = _GapApi();
    final gapCubit = ConversationCubit(
      conversationId: chatId,
      repository: ApiChatsRepository(
        gapApi,
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => true,
      currentUserId: () => meId,
      pollInterval: const Duration(hours: 1),
      detailsInterval: const Duration(hours: 1),
    );
    gapCubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    await gapCubit.load();
    expect(gapCubit.state.messages.map((m) => m.id), [messageId]);

    gapApi.phase = 1;
    await gapCubit.debugPollOnce();
    expect(gapCubit.state.messages.map((m) => m.id).toSet(), {
      messageId,
      gapId,
      newerId,
    });
    await gapCubit.close();
  });

  test('poll does not restore locally deleted tombstones', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'mine', isMine: true)],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api, pollInterval: const Duration(hours: 1));
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    cubit.toggleSelection(messageId);
    await cubit.deleteSelected();
    expect(cubit.state.messages.single.deleted, isTrue);

    api.messagesResponse = {
      'success': true,
      'data': {
        'items': [
          _message(id: messageId, text: 'mine', isMine: true, deleted: false),
        ],
        'hasMore': false,
        'nextBefore': null,
      },
    };
    await cubit.debugPollOnce();
    expect(cubit.state.messages.single.deleted, isTrue);
    expect(cubit.state.messages.single.text, isEmpty);
    await cubit.close();
  });

  test('silent poll failures do not clear messages or set error', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'keep')],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api, pollInterval: const Duration(hours: 1));
    cubit.setLifecycle(visible: true, foreground: true);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    api.messagesError = DioException(
      requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
    );
    await cubit.debugPollOnce();
    expect(cubit.state.messages, isNotEmpty);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('logout stops polling and ignores late responses', () {
    fakeAsync((async) {
      var current = true;
      final api = _Api()
        ..messagesResponse = {
          'success': true,
          'data': {
            'items': [_message(id: messageId, text: 'a')],
            'hasMore': false,
            'nextBefore': null,
          },
        };
      final cubit = _cubit(api, isCurrentAccount: () => current);
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isTrue);

      current = false;
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isFalse);

      api.messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: newerId, text: 'leak')],
          'hasMore': false,
          'nextBefore': null,
        },
      };
      async.elapse(const Duration(seconds: 20));
      async.flushMicrotasks();
      expect(cubit.state.messages.any((m) => m.id == newerId), isFalse);
      cubit.close();
      async.flushMicrotasks();
    });
  });

  test('dispose cancels timer', () {
    fakeAsync((async) {
      final api = _Api();
      final cubit = _cubit(api);
      async.flushMicrotasks();
      cubit.setLifecycle(visible: true, foreground: true);
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isTrue);
      cubit.close();
      async.flushMicrotasks();
      expect(cubit.isPollingScheduled, isFalse);
      final calls = api.messageCalls;
      async.elapse(const Duration(seconds: 30));
      async.flushMicrotasks();
      expect(api.messageCalls, calls);
    });
  });
}

class _GapApi extends ApiClient {
  int phase = 0;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    if (!endpoint.contains('/messages')) {
      return {'success': true, 'data': _detail()};
    }
    if (phase == 0) {
      return {
        'success': true,
        'data': {
          'items': [
            _message(
              id: messageId,
              text: 'seed',
              createdAt: '2026-11-20T09:00:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    }
    if (endpoint.contains('before=')) {
      return {
        'success': true,
        'data': {
          'items': [
            _message(
              id: gapId,
              text: 'gap',
              createdAt: '2026-11-20T10:00:00.000Z',
            ),
            _message(
              id: messageId,
              text: 'seed',
              createdAt: '2026-11-20T09:00:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    }
    return {
      'success': true,
      'data': {
        'items': [
          _message(
            id: newerId,
            text: 'newest',
            createdAt: '2026-11-20T11:00:00.000Z',
          ),
          _message(
            id: gapId,
            text: 'gap',
            createdAt: '2026-11-20T10:00:00.000Z',
          ),
        ],
        'hasMore': true,
        'nextBefore': gapId,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return {
      'success': true,
      'data': {'read': 1},
    };
  }
}
