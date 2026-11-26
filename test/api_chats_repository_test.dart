import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/reports/data/api_reports_repository.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  final deletes = <String>[];
  final multiparts = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  final tokens = <String?>[];
  Map<String, dynamic>? getResponse;
  Map<String, dynamic>? postResponse;
  Map<String, dynamic>? deleteResponse;
  Map<String, dynamic>? uploadResponse;
  Object? getError;
  Object? postError;
  Object? deleteError;
  Object? uploadError;
  bool accountStillCurrent = true;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    tokens.add(token);
    if (getError != null) throw getError!;
    return Map<String, dynamic>.from(
      getResponse ?? {'success': true, 'data': {}},
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
    tokens.add(token);
    if (postError != null) throw postError!;
    return Map<String, dynamic>.from(
      postResponse ?? {'success': true, 'data': <String, dynamic>{}},
    );
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
  }) async {
    deletes.add(endpoint);
    tokens.add(token);
    if (deleteError != null) throw deleteError!;
    return Map<String, dynamic>.from(
      deleteResponse ?? {'success': true, 'data': <String, dynamic>{}},
    );
  }

  @override
  Future<Map<String, dynamic>> postMultipart(
    String endpoint, {
    required FormData data,
    required String token,
  }) async {
    multiparts.add(endpoint);
    tokens.add(token);
    expect(data.files.map((f) => f.key), ['file']);
    if (uploadError != null) throw uploadError!;
    return Map<String, dynamic>.from(
      uploadResponse ??
          {
            'success': true,
            'data': {
              'url': 'https://cdn.example/chat.webp',
              'purpose': 'chat',
              'contentType': 'image/webp',
            },
          },
    );
  }
}

const chatId = '11111111-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';
const messageId = '33333333-3333-4333-8333-333333333333';

Map<String, dynamic> _user() => {
  'id': userId,
  'name': 'Sara',
  'username': 'sara',
  'avatarUrl': null,
  'verified': false,
};

Map<String, dynamic> _message({
  String id = messageId,
  String? text = 'Hi',
  String? imageUrl,
  String type = 'text',
}) => {
  'id': id,
  'conversationId': chatId,
  'senderId': userId,
  'isMine': true,
  'type': type,
  'text': text,
  'imageUrl': imageUrl,
  'deleted': false,
  'deletedBy': null,
  'readAt': null,
  'createdAt': '2026-11-20T09:00:00.000Z',
};

Map<String, dynamic> _detail() => {
  'id': chatId,
  'user': _user(),
  'canSend': true,
  'cannotSendReason': null,
  'blockedByHywork': null,
  'iBlocked': false,
  'blockedMe': false,
  'warnings': <dynamic>[],
  'unreadCount': 0,
  'lastMessageAt': '2026-11-20T09:00:00.000Z',
};

ApiChatsRepository _repo(
  _Api api, {
  bool Function()? isCurrentAccount,
  Future<void> Function()? onUnauthorized,
}) {
  return ApiChatsRepository(
    api,
    _Tokens(),
    isCurrentAccount: isCurrentAccount ?? () => api.accountStillCurrent,
    onUnauthorized: onUnauthorized ?? () async {},
  );
}

void main() {
  test(
    'GET /chats retrieves authenticated page with search and pagination',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {
            'items': [
              {
                'id': chatId,
                'user': _user(),
                'lastMessage': _message(),
                'lastMessageAt': '2026-11-20T09:00:00.000Z',
                'unreadCount': 1,
                'canSend': true,
                'blockedByHywork': false,
                'iBlocked': false,
              },
            ],
            'total': 1,
            'page': 2,
            'limit': 10,
          },
        };
      final page = await _repo(api).list(page: 2, limit: 10, q: 'sara');
      expect(api.gets.single, 'chats?page=2&limit=10&q=sara');
      expect(api.tokens.single, 'test-token');
      expect(page.items.single.user.username, 'sara');
      expect(page.page, 2);
    },
  );

  test('POST /chats opens conversation with userId only', () async {
    final api = _Api()..postResponse = {'success': true, 'data': _detail()};
    final detail = await _repo(api).openChat(userId);
    expect(api.posts.single, 'chats');
    expect(api.bodies.single, {'userId': userId});
    expect(detail.id, chatId);
    expect(detail.user.id, userId);
  });

  test('GET /chats/unread-count returns chats and messages', () async {
    final api = _Api()
      ..getResponse = {
        'success': true,
        'data': {'chats': 2, 'messages': 5},
      };
    final count = await _repo(api).unreadCount();
    expect(api.gets.single, 'chats/unread-count');
    expect(count.chats, 2);
    expect(count.messages, 5);
  });

  test('GET /chats/unread-count does not replace failures with zero', () async {
    final api = _Api()
      ..getResponse = {
        'success': true,
        'data': {'chats': 1},
      };
    await expectLater(_repo(api).unreadCount(), throwsFormatException);

    api
      ..getError = DioException(
        requestOptions: RequestOptions(path: 'chats/unread-count'),
        type: DioExceptionType.connectionError,
      )
      ..gets.clear();
    await expectLater(_repo(api).unreadCount(), throwsA(isA<DioException>()));
  });

  test(
    'GET /chats/{id} returns detail with restrictions and warnings',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {
            ..._detail(),
            'canSend': false,
            'cannotSendReason': ChatCannotSendReason.blockedByHywork,
            'warnings': [
              {
                'id': '44444444-4444-4444-8444-444444444444',
                'message': 'Be respectful.',
                'createdAt': '2026-11-19T09:00:00.000Z',
              },
            ],
          },
        };
      final detail = await _repo(api).getChat(chatId);
      expect(api.gets.single, 'chats/$chatId');
      expect(detail.cannotSendReason, ChatCannotSendReason.blockedByHywork);
      expect(detail.warnings.single.message, 'Be respectful.');
    },
  );

  test(
    'GET /chats/{id}/messages uses before cursor and newest-first page',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {
            'items': [_message()],
            'hasMore': true,
            'nextBefore': messageId,
          },
        };
      final page = await _repo(api)
          .listMessages(chatId, before: messageId, limit: 30);
      expect(
        api.gets.single,
        'chats/$chatId/messages?limit=30&before=$messageId',
      );
      expect(page.hasMore, isTrue);
      expect(page.nextBefore, messageId);
      expect(page.items.single.type, BackendChatMessageType.text);
    },
  );

  test('POST /chats/{id}/messages sends text body', () async {
    final api = _Api()
      ..postResponse = {'success': true, 'data': _message(text: 'Hello')};
    final message = await _repo(api).sendMessage(chatId, text: 'Hello');
    expect(api.posts.single, 'chats/$chatId/messages');
    expect(api.bodies.single, {'text': 'Hello'});
    expect(message.text, 'Hello');
  });

  test(
    'uploadChatImage uses purpose=chat then sendMessage uses imageUrl',
    () async {
      final dir = await Directory.systemTemp.createTemp('hywork_chat_');
      final file = File('${dir.path}/photo.png');
      await file.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);
      final api = _Api()
        ..uploadResponse = {
          'success': true,
          'data': {
            'url': 'https://cdn.example/chat.webp',
            'purpose': 'chat',
            'width': 800,
            'height': 600,
            'size': 12,
            'contentType': 'image/webp',
          },
        }
        ..postResponse = {
          'success': true,
          'data': _message(
            type: 'image',
            text: null,
            imageUrl: 'https://cdn.example/chat.webp',
          ),
        };

      final upload = await _repo(api).uploadChatImage(file);
      expect(api.multiparts.single, 'uploads?purpose=chat');
      expect(upload.purpose, 'chat');

      final sent = await _repo(api).sendMessage(chatId, imageUrl: upload.url);
      expect(api.bodies.last, {'imageUrl': 'https://cdn.example/chat.webp'});
      expect(sent.imageUrl, upload.url);

      await dir.delete(recursive: true);
    },
  );

  test('sendImageMessage does not claim success if message POST fails after upload', () async {
    final dir = await Directory.systemTemp.createTemp('hywork_chat_');
    final file = File('${dir.path}/photo.png');
    await file.writeAsBytes([137, 80, 78, 71, 13, 10, 26, 10, 1, 2, 3]);
    final api = _Api()
      ..postError = DioException(
        requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
        type: DioExceptionType.receiveTimeout,
      );
    await expectLater(
      _repo(api).sendImageMessage(chatId, file),
      throwsA(isA<DioException>()),
    );
    expect(api.multiparts, ['uploads?purpose=chat']);
    expect(api.posts, ['chats/$chatId/messages']);
    await dir.delete(recursive: true);
  });

  test('POST /chats/{id}/read returns confirmed read count', () async {
    final api = _Api()
      ..postResponse = {
        'success': true,
        'data': {'read': 3},
      };
    final result = await _repo(api).markRead(chatId);
    expect(api.posts.single, 'chats/$chatId/read');
    expect(result.read, 3);
  });

  test(
    'DELETE /chats/{id}/messages/{messageId} confirms soft delete',
    () async {
      final api = _Api();
      await _repo(api).deleteMessage(chatId, messageId);
      expect(api.deletes.single, 'chats/$chatId/messages/$messageId');
    },
  );

  test('prevents duplicate in-flight message submissions', () async {
    final gate = Completer<void>();
    final api = _GatedApi(gate)
      ..postResponse = {'success': true, 'data': _message(text: 'Hi')};
    final repo = _repo(api);
    final first = repo.sendMessage(chatId, text: 'Hi');
    await expectLater(
      repo.sendMessage(chatId, text: 'Hi'),
      throwsFormatException,
    );
    gate.complete();
    await first;
  });

  test('propagates unauthorized and invokes onUnauthorized', () async {
    var logout = 0;
    final api = _Api()
      ..getError = DioException(
        requestOptions: RequestOptions(path: 'chats'),
        response: Response(
          requestOptions: RequestOptions(path: 'chats'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
    await expectLater(
      _repo(
        api,
        onUnauthorized: () async {
          logout++;
        },
      ).list(),
      throwsA(isA<DioException>()),
    );
    expect(logout, 1);
  });

  test(
    'rejects requests after logout and discards mid-flight account changes',
    () async {
      final api = _Api()..accountStillCurrent = false;
      await expectLater(_repo(api).list(), throwsFormatException);
      expect(api.gets, isEmpty);

      final switching = _SwitchingApi()
        ..getResponse = {
          'success': true,
          'data': {'items': <dynamic>[], 'total': 0, 'page': 1, 'limit': 20},
        };
      final repo = ApiChatsRepository(
        switching,
        _Tokens(),
        isCurrentAccount: () => switching.current,
        onUnauthorized: () async {},
      );
      await expectLater(repo.list(), throwsFormatException);
    },
  );

  test(
    'message reporting remains available via ApiReportsRepository targetType',
    () {
      expect(
        ReportTargetType.values.contains(ReportTargetType.message),
        isTrue,
      );
    },
  );

  test('uncertain network errors do not claim message send success', () async {
    final api = _Api()
      ..postError = DioException(
        requestOptions: RequestOptions(path: 'chats/$chatId/messages'),
        type: DioExceptionType.connectionTimeout,
      );
    await expectLater(
      _repo(api).sendMessage(chatId, text: 'Hi'),
      throwsA(isA<DioException>()),
    );
  });
}

class _SwitchingApi extends _Api {
  bool current = true;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    final response = await super.get(endpoint, token: token);
    current = false;
    return response;
  }
}

class _GatedApi extends _Api {
  _GatedApi(this.gate);
  final Completer<void> gate;

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    posts.add(endpoint);
    bodies.add(data);
    tokens.add(token);
    await gate.future;
    if (postError != null) throw postError!;
    return Map<String, dynamic>.from(
      postResponse ?? {'success': true, 'data': <String, dynamic>{}},
    );
  }
}
