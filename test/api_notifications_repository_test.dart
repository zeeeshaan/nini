import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';

class _Tokens extends SecureTokenStore {
  _Tokens([this.value = 'test-token']);
  String? value;

  @override
  Future<String?> getToken() async => value;
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  final deletes = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  final deleteBodies = <Map<String, dynamic>?>[];
  final tokens = <String?>[];
  Map<String, dynamic>? getResponse;
  Map<String, dynamic>? postResponse;
  Map<String, dynamic>? deleteResponse;
  Object? getError;
  Object? postError;
  Object? deleteError;
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
      getResponse ??
          {
            'success': true,
            'data': {
              'items': <dynamic>[],
              'total': 0,
              'page': 1,
              'limit': 20,
              'unreadCount': 0,
            },
          },
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
      postResponse ??
          {
            'success': true,
            'data': {'updated': 1, 'unreadCount': 0},
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
    deleteBodies.add(data);
    tokens.add(token);
    if (deleteError != null) throw deleteError!;
    return Map<String, dynamic>.from(
      deleteResponse ??
          {
            'success': true,
            'data': {'removed': 1},
          },
    );
  }
}

ApiNotificationsRepository _repo(
  _Api api, {
  bool Function()? isCurrentAccount,
  Future<void> Function()? onUnauthorized,
  _Tokens? tokens,
}) {
  return ApiNotificationsRepository(
    api,
    tokens ?? _Tokens(),
    isCurrentAccount: isCurrentAccount ?? () => api.accountStillCurrent,
    onUnauthorized: onUnauthorized ?? () async {},
  );
}

Map<String, dynamic> _notification({
  String id = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
  String? targetType = 'post',
  Object? targetId = '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99',
}) {
  return {
    'id': id,
    'type': 'post.approved',
    'title': 'Post approved',
    'body': '“iPhone 13” is now live.',
    'titleFa': 'آگهی تأیید شد',
    'bodyFa': '“iPhone 13” منتشر شد.',
    'target': targetType == null ? null : {'type': targetType, 'id': targetId},
    'data': <String, dynamic>{},
    'isRead': false,
    'readAt': null,
    'createdAt': '2026-11-20T09:00:00.000Z',
  };
}

void main() {
  test(
    'GET /notifications retrieves authenticated page with bilingual fields',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {
            'items': [_notification()],
            'total': 1,
            'page': 1,
            'limit': 20,
            'unreadCount': 1,
          },
        };
      final page = await _repo(api).list(page: 1, limit: 20);
      expect(api.gets.single, 'notifications?page=1&limit=20');
      expect(api.tokens.single, 'test-token');
      expect(page.items, hasLength(1));
      expect(page.items.single.title, 'Post approved');
      expect(page.items.single.titleFa, 'آگهی تأیید شد');
      expect(page.items.single.target?.type, NotificationTargetType.post);
      expect(page.unreadCount, 1);
    },
  );

  test(
    'GET /notifications supports unreadOnly and pagination query params',
    () async {
      final api = _Api();
      await _repo(api).list(page: 2, limit: 10, unreadOnly: true);
      expect(api.gets.single, 'notifications?page=2&limit=10&unreadOnly=true');
    },
  );

  test(
    'GET /notifications returns an empty page without fabricating items',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {
            'items': <dynamic>[],
            'total': 0,
            'page': 1,
            'limit': 20,
            'unreadCount': 0,
          },
        };
      final page = await _repo(api).list();
      expect(page.items, isEmpty);
      expect(page.total, 0);
    },
  );

  test('GET /notifications rejects invalid page filters', () async {
    final api = _Api();
    final repo = _repo(api);
    await expectLater(repo.list(page: 0), throwsFormatException);
    await expectLater(repo.list(limit: 51), throwsFormatException);
    expect(api.gets, isEmpty);
  });

  test(
    'GET /notifications/unread-count returns the documented count',
    () async {
      final api = _Api()
        ..getResponse = {
          'success': true,
          'data': {'count': 3},
        };
      final count = await _repo(api).unreadCount();
      expect(api.gets.single, 'notifications/unread-count');
      expect(count, 3);
    },
  );

  test(
    'GET /notifications/unread-count does not replace failures with zero',
    () async {
      final api = _Api()
        ..getResponse = {'success': true, 'data': <String, dynamic>{}};
      await expectLater(_repo(api).unreadCount(), throwsFormatException);

      api
        ..getResponse = {
          'success': false,
          'data': {'count': 0},
        }
        ..gets.clear();
      await expectLater(_repo(api).unreadCount(), throwsFormatException);

      api
        ..getError = DioException(
          requestOptions: RequestOptions(path: 'notifications/unread-count'),
          type: DioExceptionType.connectionError,
        )
        ..gets.clear();
      await expectLater(_repo(api).unreadCount(), throwsA(isA<DioException>()));
    },
  );

  test('POST /notifications/read marks selected ids', () async {
    final api = _Api()
      ..postResponse = {
        'success': true,
        'data': {'updated': 2, 'unreadCount': 1},
      };
    final result = await _repo(api).markRead(
      ids: const [
        '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
        '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20',
      ],
    );
    expect(api.posts.single, 'notifications/read');
    expect(api.bodies.single, {
      'ids': [
        '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
        '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20',
      ],
    });
    expect(result.updated, 2);
    expect(result.unreadCount, 1);
  });

  test('POST /notifications/read supports mark-all', () async {
    final api = _Api();
    await _repo(api).markRead(markAll: true);
    expect(api.bodies.single, {'all': true});
  });

  test('POST /notifications/read rejects empty or invalid requests', () async {
    final api = _Api();
    final repo = _repo(api);
    await expectLater(repo.markRead(), throwsFormatException);
    await expectLater(repo.markRead(ids: const []), throwsFormatException);
    await expectLater(
      repo.markRead(ids: const ['not-a-uuid']),
      throwsFormatException,
    );
    await expectLater(
      repo.markRead(
        markAll: true,
        ids: const ['0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'],
      ),
      throwsFormatException,
    );
    expect(api.posts, isEmpty);
  });

  test(
    'POST /notifications/read requires a confirmed success envelope',
    () async {
      final api = _Api()
        ..postResponse = {
          'success': true,
          'data': {'updated': 1},
        };
      await expectLater(
        _repo(api).markRead(markAll: true),
        throwsFormatException,
      );
    },
  );

  test('propagates unauthorized and invokes onUnauthorized', () async {
    var logout = 0;
    final api = _Api()
      ..getError = DioException(
        requestOptions: RequestOptions(path: 'notifications'),
        response: Response(
          requestOptions: RequestOptions(path: 'notifications'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
    final repo = _repo(
      api,
      onUnauthorized: () async {
        logout++;
      },
    );
    await expectLater(repo.list(), throwsA(isA<DioException>()));
    expect(logout, 1);
  });

  test('rejects requests after logout or account switch', () async {
    final api = _Api()..accountStillCurrent = false;
    await expectLater(_repo(api).list(), throwsFormatException);
    await expectLater(_repo(api).unreadCount(), throwsFormatException);
    expect(api.gets, isEmpty);
  });

  test(
    'discards successful responses when the account changed mid-flight',
    () async {
      final switching = _SwitchingApi()
        ..getResponse = {
          'success': true,
          'data': {
            'items': [_notification()],
            'total': 1,
            'page': 1,
            'limit': 20,
            'unreadCount': 1,
          },
        };
      final repo = ApiNotificationsRepository(
        switching,
        _Tokens(),
        isCurrentAccount: () => switching.current,
        onUnauthorized: () async {},
      );
      await expectLater(repo.list(), throwsFormatException);
    },
  );

  test(
    'rejects missing authentication token without fabricating data',
    () async {
      var logout = 0;
      final api = _Api();
      final repo = _repo(
        api,
        tokens: _Tokens(null),
        onUnauthorized: () async {
          logout++;
        },
      );
      await expectLater(repo.list(), throwsFormatException);
      expect(logout, 1);
      expect(api.gets, isEmpty);
    },
  );

  test('propagates network failures without claiming success', () async {
    final api = _Api()
      ..getError = DioException(
        requestOptions: RequestOptions(path: 'notifications'),
        type: DioExceptionType.connectionTimeout,
      );
    await expectLater(_repo(api).list(), throwsA(isA<DioException>()));
  });

  test(
    'POST /notifications/devices registers the traditional FCM token',
    () async {
      final api = _Api()
        ..postResponse = {
          'success': true,
          'data': {'registered': true, 'platform': 'android', 'locale': 'fa'},
        };
      final result = await _repo(api).registerDevice(
        fcmToken: 'fcm-token-from-the-app',
        platform: NotificationDevicePlatform.android,
        locale: NotificationDeviceLocale.fa,
      );
      expect(api.posts.single, 'notifications/devices');
      expect(api.bodies.single, {
        'token': 'fcm-token-from-the-app',
        'platform': 'android',
        'locale': 'fa',
      });
      expect(result.registered, isTrue);
      expect(result.platform, 'android');
      expect(result.locale, 'fa');
    },
  );

  test('POST /notifications/devices rejects invalid input', () async {
    final api = _Api();
    final repo = _repo(api);
    await expectLater(
      repo.registerDevice(fcmToken: '', platform: 'android'),
      throwsFormatException,
    );
    await expectLater(
      repo.registerDevice(fcmToken: 'token', platform: 'desktop'),
      throwsFormatException,
    );
    await expectLater(
      repo.registerDevice(fcmToken: 'token', platform: 'android', locale: 'de'),
      throwsFormatException,
    );
    expect(api.posts, isEmpty);
  });

  test(
    'POST /notifications/devices requires a confirmed success envelope',
    () async {
      final api = _Api()
        ..postResponse = {
          'success': true,
          'data': {'registered': false, 'platform': 'android', 'locale': 'fa'},
        };
      final result = await _repo(api)
          .registerDevice(fcmToken: 'token', platform: 'android');
      expect(result.registered, isFalse);

      api.postResponse = {
        'success': true,
        'data': {'platform': 'android', 'locale': 'fa'},
      };
      await expectLater(
        _repo(api).registerDevice(fcmToken: 'token', platform: 'android'),
        throwsFormatException,
      );
    },
  );

  test(
    'DELETE /notifications/devices removes the traditional FCM token',
    () async {
      final api = _Api()
        ..deleteResponse = {
          'success': true,
          'data': {'removed': 1},
        };
      final result = await _repo(api)
          .unregisterDevice(fcmToken: 'fcm-token-from-the-app');
      expect(api.deletes.single, 'notifications/devices');
      expect(api.deleteBodies.single, {'token': 'fcm-token-from-the-app'});
      expect(result.removed, 1);
    },
  );

  test(
    'device registration rejects stale responses after account switch',
    () async {
      final switching = _SwitchingApi()
        ..postResponse = {
          'success': true,
          'data': {'registered': true, 'platform': 'android', 'locale': 'fa'},
        };
      final repo = ApiNotificationsRepository(
        switching,
        _Tokens(),
        isCurrentAccount: () => switching.current,
        onUnauthorized: () async {},
      );
      await expectLater(
        repo.registerDevice(fcmToken: 'token', platform: 'android'),
        throwsFormatException,
      );
    },
  );
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

  @override
  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    final response = await super.post(endpoint, data: data, token: token);
    current = false;
    return response;
  }
}
