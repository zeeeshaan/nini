import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_inbox_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  final gets = <String>[];
  Map<String, dynamic>? listResponse;
  Object? listError;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    if (listError != null) throw listError!;
    return Map<String, dynamic>.from(
      listResponse ??
          {
            'success': true,
            'data': {'items': <dynamic>[], 'total': 0, 'page': 1, 'limit': 20},
          },
    );
  }
}

class _SearchApi extends ApiClient {
  String? lastQ;
  int calls = 0;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    calls++;
    final uri = Uri.parse(
      endpoint.contains('?') ? 'x://x/$endpoint' : 'x://x/$endpoint',
    );
    lastQ = uri.queryParameters['q'];
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final name = lastQ == 'new' ? 'New' : (lastQ == 'old' ? 'Old' : 'Initial');
    final id = lastQ == 'new'
        ? '44444444-4444-4444-8444-444444444444'
        : '11111111-1111-4111-8111-111111111111';
    return {
      'success': true,
      'data': {
        'items': [
          {
            'id': id,
            'user': {
              'id': '22222222-2222-4222-8222-222222222222',
              'name': name,
              'username': 'seller',
              'avatarUrl': null,
              'verified': false,
            },
            'lastMessage': null,
            'lastMessageAt': '2026-11-20T09:00:00.000Z',
            'unreadCount': 0,
            'canSend': true,
            'blockedByHywork': false,
            'iBlocked': false,
          },
        ],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
  }
}

const chatId = '11111111-1111-4111-8111-111111111111';
const userId = '22222222-2222-4222-8222-222222222222';

Map<String, dynamic> _chatItem({
  required String id,
  int unread = 0,
  String name = 'Seller',
}) {
  return {
    'id': id,
    'user': {
      'id': userId,
      'name': name,
      'username': 'seller',
      'avatarUrl': null,
      'verified': false,
    },
    'lastMessage': null,
    'lastMessageAt': '2026-11-20T09:00:00.000Z',
    'unreadCount': unread,
    'canSend': true,
    'blockedByHywork': false,
    'iBlocked': false,
  };
}

ChatInboxCubit _cubit(_Api api, {bool Function()? isCurrentAccount}) {
  var current = true;
  return ChatInboxCubit(
    ApiChatsRepository(
      api,
      _Tokens(),
      isCurrentAccount: isCurrentAccount ?? () => current,
      onUnauthorized: () async {
        current = false;
      },
    ),
    isCurrentAccount: isCurrentAccount ?? () => current,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('loads chats and paginates without duplicates', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_chatItem(id: chatId, unread: 2)],
          'total': 40,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.conversations, hasLength(1));
    expect(cubit.state.conversations.single.unreadCount, 2);
    expect(cubit.state.hasMore, isTrue);

    api.listResponse = {
      'success': true,
      'data': {
        'items': [
          _chatItem(id: '44444444-4444-4444-8444-444444444444', name: 'Other'),
        ],
        'total': 40,
        'page': 2,
        'limit': 20,
      },
    };
    await cubit.loadMore();
    expect(cubit.state.conversations, hasLength(2));
    await cubit.close();
  });

  test('search ignores stale responses', () async {
    final api = _SearchApi();
    final cubit = ChatInboxCubit(
      ApiChatsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => true,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => true,
    );
    await Future<void>.delayed(const Duration(milliseconds: 80));
    cubit.search('old');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    cubit.search('new');
    await Future<void>.delayed(const Duration(milliseconds: 450));
    expect(cubit.state.query, 'new');
    expect(cubit.state.conversations, isNotEmpty);
    expect(cubit.state.conversations.single.name, 'New');
    await cubit.close();
  });

  test('load failure keeps empty list and shows error', () async {
    final api = _Api()
      ..listError = DioException(requestOptions: RequestOptions(path: 'chats'));
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.conversations, isEmpty);
    expect(cubit.state.error, ChatStrings.loadFailed);
    await cubit.close();
  });

  test('focus refresh preserves search query', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_chatItem(id: chatId, name: 'Alpha')],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = _cubit(api);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    cubit.search('seller');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    expect(cubit.state.query, 'seller');
    api.listResponse = {
      'success': true,
      'data': {
        'items': [_chatItem(id: chatId, name: 'Seller Match')],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
    await cubit.refresh();
    expect(cubit.state.query, 'seller');
    expect(api.gets.last.contains('q=seller'), isTrue);
    await cubit.close();
  });

  test('account switch clears inbox', () async {
    var current = true;
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_chatItem(id: chatId)],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = _cubit(api, isCurrentAccount: () => current);
    await Future<void>.delayed(Duration.zero);
    await cubit.load();
    expect(cubit.state.conversations, isNotEmpty);
    current = false;
    await cubit.load();
    expect(cubit.state.conversations, isEmpty);
    await cubit.close();
  });
}
