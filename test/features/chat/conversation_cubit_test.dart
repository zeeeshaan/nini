import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  final deletes = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  Map<String, dynamic>? detailResponse;
  Map<String, dynamic>? messagesResponse;
  Map<String, dynamic>? sendResponse;
  Map<String, dynamic>? readResponse;
  Object? detailError;
  Object? messagesError;
  Object? sendError;
  Object? deleteError;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    if (endpoint.contains('/messages')) {
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
    if (detailError != null) throw detailError!;
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
    bodies.add(data);
    if (endpoint.endsWith('/read')) {
      return Map<String, dynamic>.from(
        readResponse ??
            {
              'success': true,
              'data': {'read': 1},
            },
      );
    }
    if (sendError != null) throw sendError!;
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
    deletes.add(endpoint);
    if (deleteError != null) throw deleteError!;
    return {'success': true, 'data': <String, dynamic>{}};
  }
}

const chatId = '11111111-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';
const messageId = '33333333-3333-4333-8333-333333333333';
const olderId = '44444444-4444-4444-8444-444444444444';
const meId = '55555555-5555-4555-8555-555555555555';

Map<String, dynamic> _detail({
  bool canSend = true,
  String? cannotSendReason,
  bool iBlocked = false,
  List<Map<String, dynamic>> warnings = const [],
}) {
  return {
    'id': chatId,
    'user': {
      'id': userId,
      'name': 'Peer',
      'username': 'peer',
      'avatarUrl': null,
      'verified': false,
    },
    'canSend': canSend,
    'cannotSendReason': cannotSendReason,
    'blockedByHywork': null,
    'iBlocked': iBlocked,
    'blockedMe': false,
    'warnings': warnings,
    'unreadCount': 1,
    'lastMessageAt': '2026-11-20T10:00:00.000Z',
  };
}

Map<String, dynamic> _message({
  required String id,
  required String text,
  bool isMine = false,
  bool deleted = false,
  String type = 'text',
  String? imageUrl,
  String createdAt = '2026-11-20T10:00:00.000Z',
}) {
  return {
    'id': id,
    'conversationId': chatId,
    'senderId': isMine ? meId : userId,
    'isMine': isMine,
    'type': type,
    'text': text,
    'imageUrl': imageUrl,
    'deleted': deleted,
    'deletedBy': deleted ? 'sender' : null,
    'readAt': null,
    'createdAt': createdAt,
  };
}

ConversationCubit _cubit(
  _Api api, {
  bool Function()? isCurrentAccount,
  void Function()? onMarkedRead,
  bool activateLifecycle = true,
  Duration pollInterval = const Duration(hours: 1),
}) {
  var current = true;
  final cubit = ConversationCubit(
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
    onMarkedRead: onMarkedRead,
    pollInterval: pollInterval,
    detailsInterval: const Duration(hours: 1),
  );
  if (activateLifecycle) {
    cubit.setLifecycle(visible: true, foreground: true);
  }
  return cubit;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads detail + newest messages chronological and marks read', () async {
    var marked = false;
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: messageId,
              text: 'newer',
              createdAt: '2026-11-20T10:02:00.000Z',
            ),
            _message(
              id: olderId,
              text: 'older',
              createdAt: '2026-11-20T10:01:00.000Z',
            ),
          ],
          'hasMore': true,
          'nextBefore': olderId,
        },
      };
    final cubit = _cubit(api, onMarkedRead: () => marked = true);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.messages.map((m) => m.text), ['older', 'newer']);
    expect(cubit.state.hasMore, isTrue);
    expect(cubit.state.nextBefore, olderId);
    expect(api.posts.any((p) => p.endsWith('/read')), isTrue);
    expect(marked, isTrue);
    expect(cubit.state.markedRead, isTrue);
    await cubit.close();
  });

  test(
    'cursor pagination prepends older messages without duplicates',
    () async {
      final api = _Api()
        ..messagesResponse = {
          'success': true,
          'data': {
            'items': [
              _message(
                id: messageId,
                text: 'newer',
                createdAt: '2026-11-20T10:02:00.000Z',
              ),
            ],
            'hasMore': true,
            'nextBefore': messageId,
          },
        };
      final cubit = _cubit(api);
      await Future<void>.delayed(Duration.zero);
      await cubit.load();

      api.messagesResponse = {
        'success': true,
        'data': {
          'items': [
            _message(
              id: olderId,
              text: 'older',
              createdAt: '2026-11-20T09:00:00.000Z',
            ),
            _message(
              id: messageId,
              text: 'newer',
              createdAt: '2026-11-20T10:02:00.000Z',
            ),
          ],
          'hasMore': false,
          'nextBefore': null,
        },
      };
      await cubit.loadOlder();
      expect(cubit.state.messages.map((m) => m.id), [olderId, messageId]);
      expect(cubit.state.hasMore, isFalse);
      await cubit.close();
    },
  );

  test(
    'text send keeps input on failure and appends confirmed message',
    () async {
      final api = _Api();
      final cubit = _cubit(api);
      await Future<void>.delayed(Duration.zero);
      await cubit.load();

      final ok = await cubit.sendMessage('hello');
      expect(ok, isTrue);
      expect(cubit.state.messages.last.text, 'hello');
      expect(cubit.state.messages.last.id, messageId);

      api.sendError = DioException(
        requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
      );
      final failed = await cubit.sendMessage('again');
      expect(failed, isFalse);
      expect(cubit.state.error, ChatStrings.sendFailed);
      expect(cubit.state.messages.where((m) => m.text == 'again'), isEmpty);
      await cubit.close();
    },
  );

  test('soft delete keeps tombstone and blocks stale restore', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'mine', isMine: true)],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    cubit.toggleSelection(messageId);
    await cubit.deleteSelected();
    expect(cubit.state.messages.single.deleted, isTrue);
    expect(cubit.state.messages.single.text, isEmpty);
    expect(cubit.state.visibleMessages, isEmpty);
    expect(cubit.latestMessage, isNull);
    expect(api.deletes, ['chats/$chatId/messages/$messageId']);

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
    await cubit.refresh();
    expect(cubit.state.messages.single.deleted, isTrue);
    expect(cubit.state.messages.single.text, isEmpty);
    expect(cubit.state.visibleMessages, isEmpty);
    await cubit.close();
  });

  test('deleteSelected ignores peer messages without calling DELETE', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'theirs', isMine: false)],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.visibleMessages, hasLength(1));
    cubit.toggleSelection(messageId);
    await cubit.deleteSelected();
    expect(cubit.state.visibleMessages, hasLength(1));
    expect(cubit.state.messages.single.deleted, isFalse);
    expect(api.deletes, isEmpty);
    await cubit.close();
  });

  test('empty backend history and failures do not invent messages', () async {
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {'items': <dynamic>[], 'hasMore': false, 'nextBefore': null},
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.visibleMessages, isEmpty);

    api.messagesError = DioException(
      requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
    );
    await cubit.refresh();
    expect(cubit.state.messages, isEmpty);
    expect(cubit.state.error, ChatStrings.messagesLoadFailed);
    await cubit.close();
  });

  test('blocking restrictions disable sending', () async {
    final api = _Api()
      ..detailResponse = {
        'success': true,
        'data': _detail(
          canSend: false,
          cannotSendReason: ChatCannotSendReason.youBlockedUser,
          iBlocked: true,
        ),
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.canSend, isFalse);
    expect(cubit.state.restrictionLabel, ChatStrings.cannotSendYouBlocked);
    final sent = await cubit.sendMessage('nope');
    expect(sent, isFalse);
    expect(api.posts.where((p) => p.contains('/messages')), isEmpty);
    await cubit.close();
  });

  test('stores admin warnings from chat detail', () async {
    final api = _Api()
      ..detailResponse = {
        'success': true,
        'data': _detail(
          warnings: [
            {
              'id': '66666666-6666-4666-8666-666666666666',
              'message': 'Be respectful',
              'createdAt': '2026-11-20T08:00:00.000Z',
            },
          ],
        ),
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.warnings, hasLength(1));
    expect(cubit.state.warnings.single.message, 'Be respectful');
    await cubit.close();
  });

  test('logout mid-load does not emit foreign account messages', () async {
    var current = true;
    final api = _Api()
      ..messagesResponse = {
        'success': true,
        'data': {
          'items': [_message(id: messageId, text: 'secret')],
          'hasMore': false,
          'nextBefore': null,
        },
      };
    final cubit = _cubit(api, isCurrentAccount: () => current);
    await Future<void>.delayed(Duration.zero);
    current = false;
    await cubit.load();
    expect(cubit.state.messages, isEmpty);
    await cubit.close();
  });
}
