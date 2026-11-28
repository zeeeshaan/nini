import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/data/push_device_sync.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'auth-token';
}

class _Api extends ApiClient {
  final posts = <Map<String, dynamic>?>[];
  final deletes = <Map<String, dynamic>?>[];
  int postCalls = 0;
  int deleteCalls = 0;
  Completer<Map<String, dynamic>>? delayedPost;
  Object? postError;
  Object? deleteError;
  bool accountStillCurrent = true;

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    postCalls++;
    posts.add(data);
    if (postError != null) throw postError!;
    if (delayedPost != null) return delayedPost!.future;
    return {
      'success': true,
      'data': {'registered': true, 'platform': 'android', 'locale': 'fa'},
    };
  }

  @override
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    required String token,
    Map<String, dynamic>? data,
  }) async {
    deleteCalls++;
    deletes.add(data);
    if (deleteError != null) throw deleteError!;
    return {
      'success': true,
      'data': {'removed': 1},
    };
  }
}

void main() {
  late _Api api;
  late ApiNotificationsRepository repository;
  late PushDeviceSync sync;

  setUp(() {
    api = _Api();
    repository = ApiNotificationsRepository(
      api,
      _Tokens(),
      isCurrentAccount: () => api.accountStillCurrent,
      onUnauthorized: () async {},
    );
    sync = PushDeviceSync.instance..debugReset();
    PushNotifications.debugRemotePushSupported = true;
    PushDeviceSync.debugPlatform = 'android';
    PushNotifications.debugSetToken(null);
  });

  tearDown(() {
    sync.debugReset();
    PushNotifications.debugRemotePushSupported = null;
    PushDeviceSync.debugPlatform = null;
    PushNotifications.debugSetToken(null);
  });

  test(
    'registers after attach when an FCM token is already available',
    () async {
      PushNotifications.debugSetToken('token-a');
      sync.attach(
        repository: repository,
        isCurrentAccount: () => api.accountStillCurrent,
        userId: 'user-1',
        accountRevision: 1,
      );
      await Future<void>.delayed(Duration.zero);
      await sync.sync();
      expect(api.postCalls, 1);
      expect(api.posts.single, {
        'token': 'token-a',
        'platform': 'android',
        'locale': 'fa',
      });
    },
  );

  test('registers when the FCM token arrives after authentication', () async {
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    await sync.sync();
    expect(api.postCalls, 0);

    PushNotifications.debugSetToken('token-b');
    await Future<void>.delayed(Duration.zero);
    await sync.sync();
    expect(api.postCalls, 1);
    expect(api.posts.single?['token'], 'token-b');
  });

  test('coalesces identical in-flight registration requests', () async {
    final gate = Completer<Map<String, dynamic>>();
    api.delayedPost = gate;
    PushNotifications.debugSetToken('token-c');
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    final first = sync.sync();
    final second = sync.sync();
    expect(identical(first, second), isTrue);
    gate.complete({
      'success': true,
      'data': {'registered': true, 'platform': 'android', 'locale': 'fa'},
    });
    await Future.wait([first, second]);
    expect(api.postCalls, 1);
  });

  test('uploads a changed FCM token for the same account', () async {
    PushNotifications.debugSetToken('token-old');
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    await sync.sync();
    PushNotifications.debugSetToken('token-new');
    await sync.sync();
    expect(api.postCalls, 2);
    expect(api.posts.last?['token'], 'token-new');
  });

  test('does not permanently skip a token after a transient failure', () async {
    PushNotifications.debugSetToken('token-retry');
    api.postError = DioException(
      requestOptions: RequestOptions(path: 'notifications/devices'),
      type: DioExceptionType.connectionTimeout,
    );
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    await sync.sync();
    expect(api.postCalls, 1);

    api.postError = null;
    await sync.sync();
    expect(api.postCalls, 2);
  });

  test(
    'unregister runs before logout and clears pending registration',
    () async {
      PushNotifications.debugSetToken('token-out');
      sync.attach(
        repository: repository,
        isCurrentAccount: () => api.accountStillCurrent,
        userId: 'user-1',
        accountRevision: 1,
      );
      await sync.sync();
      await sync.unregisterBestEffort();
      expect(api.deleteCalls, 1);
      expect(api.deletes.single, {'token': 'token-out'});

      // Stale register must not run after logout begins.
      await sync.sync();
      expect(api.postCalls, 1);
    },
  );

  test('stale registration is ignored after account switch', () async {
    final gate = Completer<Map<String, dynamic>>();
    api.delayedPost = gate;
    PushNotifications.debugSetToken('token-switch');
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    final pending = sync.sync();
    // Wait until the authenticated POST is in flight before switching.
    for (var i = 0; i < 40 && api.postCalls == 0; i++) {
      await Future<void>.delayed(Duration.zero);
    }
    expect(api.postCalls, 1);
    api.accountStillCurrent = false;
    sync.detach(accountRevision: 1);
    gate.complete({
      'success': true,
      'data': {'registered': true, 'platform': 'android', 'locale': 'fa'},
    });
    await pending;
    // No confirmed retry/upload for the old account.
    api.accountStillCurrent = true;
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-2',
      accountRevision: 2,
    );
    await sync.sync();
    expect(api.postCalls, 2);
    expect(api.posts.last?['token'], 'token-switch');
  });

  test('unregister failure does not throw', () async {
    PushNotifications.debugSetToken('token-fail');
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    await sync.sync();
    api.deleteError = DioException(
      requestOptions: RequestOptions(path: 'notifications/devices'),
      type: DioExceptionType.connectionError,
    );
    await expectLater(sync.unregisterBestEffort(), completes);
  });

  test(
    'onLogoutAborted clears the logout guard so registration can resume',
    () async {
      PushNotifications.debugSetToken('token-abort');
      sync.attach(
        repository: repository,
        isCurrentAccount: () => api.accountStillCurrent,
        userId: 'user-1',
        accountRevision: 1,
      );
      await sync.sync();
      expect(api.postCalls, 1);

      await sync.unregisterBestEffort();
      expect(api.deleteCalls, 1);

      // Guard must block re-register while logout is still in progress.
      await sync.sync();
      expect(api.postCalls, 1);

      sync.onLogoutAborted();
      await Future<void>.delayed(Duration.zero);
      await sync.sync();
      expect(api.postCalls, 2);
    },
  );

  test('skips registration when remote push is unsupported', () async {
    PushNotifications.debugRemotePushSupported = false;
    PushNotifications.debugSetToken('token-ios');
    sync.attach(
      repository: repository,
      isCurrentAccount: () => api.accountStillCurrent,
      userId: 'user-1',
      accountRevision: 1,
    );
    await sync.sync();
    expect(api.postCalls, 0);
  });
}
