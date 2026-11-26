import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  Map<String, dynamic>? response;
  Object? error;
  int calls = 0;
  final Completer<void> gate = Completer<void>();
  bool useGate = false;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    calls++;
    if (useGate) await gate.future;
    if (error != null) throw error!;
    return Map<String, dynamic>.from(
      response ??
          {
            'success': true,
            'data': {'chats': 0, 'messages': 0},
          },
    );
  }
}

ChatUnreadCubit _cubit(_Api api, {bool Function()? isCurrentAccount}) {
  var current = true;
  return ChatUnreadCubit(
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

  test('badge uses chats count, not messages', () async {
    final api = _Api()
      ..response = {
        'success': true,
        'data': {'chats': 3, 'messages': 12},
      };
    final cubit = _cubit(api);
    await cubit.refresh();
    expect(cubit.state.chats, 3);
    expect(cubit.state.messages, 12);
    expect(cubit.state.badgeCount, 3);
    await cubit.close();
  });

  test('failed unread request does not fabricate zero', () async {
    final api = _Api()
      ..response = {
        'success': true,
        'data': {'chats': 4, 'messages': 7},
      };
    final cubit = _cubit(api);
    await cubit.refresh();
    expect(cubit.state.chats, 4);

    api.error = DioException(
      requestOptions: RequestOptions(path: 'chats/unread-count'),
    );
    await cubit.refresh();
    expect(cubit.state.chats, 4);
    await cubit.close();
  });

  test('coalesces concurrent unread requests from multiple widgets', () async {
    final api = _Api()
      ..useGate = true
      ..response = {
        'success': true,
        'data': {'chats': 5, 'messages': 8},
      };
    final cubit = _cubit(api);
    final first = cubit.refresh();
    final second = cubit.refresh();
    expect(identical(first, second), isTrue);
    api.gate.complete();
    await first;
    expect(api.calls, 1);
    expect(cubit.state.chats, 5);
    await cubit.close();
  });

  test('clear resets badge on logout', () async {
    final api = _Api()
      ..response = {
        'success': true,
        'data': {'chats': 2, 'messages': 5},
      };
    final cubit = _cubit(api);
    await cubit.refresh();
    cubit.clear();
    expect(cubit.state.chats, isNull);
    expect(cubit.state.badgeCount, 0);
    await cubit.close();
  });
}
