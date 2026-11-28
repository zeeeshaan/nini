import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification_mapper.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';

class _Tokens extends SecureTokenStore {
  @override
  Future<String?> getToken() async => 'test-token';
}

class _Api extends ApiClient {
  final gets = <String>[];
  final posts = <String>[];
  final bodies = <Map<String, dynamic>?>[];
  Map<String, dynamic>? listResponse;
  Map<String, dynamic>? unreadResponse;
  Map<String, dynamic>? readResponse;
  Object? listError;
  Object? unreadError;
  Object? readError;
  int listCalls = 0;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    if (endpoint.startsWith('notifications/unread-count')) {
      if (unreadError != null) throw unreadError!;
      return Map<String, dynamic>.from(
        unreadResponse ??
            {
              'success': true,
              'data': {'count': 0},
            },
      );
    }
    listCalls++;
    if (listError != null) throw listError!;
    return Map<String, dynamic>.from(
      listResponse ??
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
    if (readError != null) throw readError!;
    return Map<String, dynamic>.from(
      readResponse ??
          {
            'success': true,
            'data': {'updated': 1, 'unreadCount': 0},
          },
    );
  }
}

Map<String, dynamic> _item({
  required String id,
  bool isRead = false,
  String? targetType = 'post',
  String targetId = '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99',
}) {
  return {
    'id': id,
    'type': 'post.approved',
    'title': 'Post approved',
    'body': 'Body EN',
    'titleFa': 'آگهی تأیید شد',
    'bodyFa': 'متن فارسی',
    'target': targetType == null ? null : {'type': targetType, 'id': targetId},
    'data': <String, dynamic>{},
    'isRead': isRead,
    'readAt': null,
    'createdAt': '2026-11-20T09:00:00.000Z',
  };
}

NotificationsCubit _cubit(_Api api, {bool Function()? isCurrentAccount}) {
  var current = true;
  return NotificationsCubit(
    ApiNotificationsRepository(
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

  test('loads notifications and unread count on create', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f')],
          'total': 1,
          'page': 1,
          'limit': 20,
          'unreadCount': 1,
        },
      }
      ..unreadResponse = {
        'success': true,
        'data': {'count': 4},
      };
    final cubit = _cubit(api);
    await cubit.load();
    await cubit.refreshUnreadCount();
    expect(cubit.state.items, hasLength(1));
    expect(cubit.state.items.single.titleFa, 'آگهی تأیید شد');
    expect(cubit.state.unreadCount, 4);
    expect(cubit.state.badgeCount, 4);
    await cubit.close();
  });

  test('keeps empty state without sample fallbacks', () async {
    final cubit = _cubit(_Api());
    await cubit.load();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.error, isNull);
    await cubit.close();
  });

  test('paginates without duplicating ids', () async {
    final api = _Api();
    final cubit = _cubit(api);
    await cubit.load();
    api.listResponse = {
      'success': true,
      'data': {
        'items': [
          _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'),
          _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20'),
        ],
        'total': 3,
        'page': 1,
        'limit': 2,
        'unreadCount': 2,
      },
    };
    await cubit.refresh();
    expect(cubit.state.hasMore, isTrue);

    api.listResponse = {
      'success': true,
      'data': {
        'items': [
          _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20'),
          _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e21'),
        ],
        'total': 3,
        'page': 2,
        'limit': 2,
      },
    };
    await cubit.loadMore();
    expect(cubit.state.items.map((item) => item.id), [
      '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
      '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20',
      '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e21',
    ]);
    await cubit.close();
  });

  test('refresh keeps existing items until replacement arrives', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f')],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = _cubit(api);
    await cubit.load();
    expect(cubit.state.items, hasLength(1));
    api.listResponse = {
      'success': true,
      'data': {
        'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e22')],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
    await cubit.refresh();
    expect(cubit.state.items.single.id, '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e22');
    await cubit.close();
  });

  test(
    'failed unread-count does not overwrite a known badge value with zero',
    () async {
      final api = _Api()
        ..unreadResponse = {
          'success': true,
          'data': {'count': 7},
        };
      final cubit = _cubit(api);
      await cubit.refreshUnreadCount();
      expect(cubit.state.unreadCount, 7);
      api.unreadError = DioException(
        requestOptions: RequestOptions(path: 'notifications/unread-count'),
        type: DioExceptionType.connectionError,
      );
      await cubit.refreshUnreadCount();
      expect(cubit.state.unreadCount, 7);
      await cubit.close();
    },
  );

  test('marks an individual notification read and syncs unreadCount', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f')],
          'total': 1,
          'page': 1,
          'limit': 20,
          'unreadCount': 1,
        },
      }
      ..readResponse = {
        'success': true,
        'data': {'updated': 1, 'unreadCount': 0},
      };
    final cubit = _cubit(api);
    await cubit.load();
    final ok = await cubit.markRead('0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f');
    expect(ok, isTrue);
    expect(api.bodies.single, {
      'ids': ['0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'],
    });
    expect(cubit.state.items.single.unreadCount, 0);
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
  });

  test('mark-all updates local read state after confirmation', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [
            _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'),
            _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20'),
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
        },
      }
      ..readResponse = {
        'success': true,
        'data': {'updated': 2, 'unreadCount': 0},
      };
    final cubit = _cubit(api);
    await cubit.load();
    expect(await cubit.markAllRead(), isTrue);
    expect(api.bodies.single, {'all': true});
    expect(cubit.state.items.every((item) => item.unreadCount == 0), isTrue);
    await cubit.close();
  });

  test('markReadFromPush updates badge without a loaded list item', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': <dynamic>[],
          'total': 0,
          'page': 1,
          'limit': 20,
          'unreadCount': 0,
        },
      }
      ..unreadResponse = {
        'success': true,
        'data': {'count': 2},
      }
      ..readResponse = {
        'success': true,
        'data': {'updated': 1, 'unreadCount': 1},
      };
    final cubit = _cubit(api);
    await cubit.load();
    await cubit.refreshUnreadCount();
    expect(cubit.state.unreadCount, 2);
    final ok = await cubit.markReadFromPush(
      '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
    );
    expect(ok, isTrue);
    expect(cubit.state.unreadCount, 1);
    expect(api.posts, contains('notifications/read'));
    await cubit.close();
  });

  test(
    'failed mark-as-read keeps unread state and surfaces actionError',
    () async {
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f')],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        }
        ..readError = DioException(
          requestOptions: RequestOptions(path: 'notifications/read'),
          type: DioExceptionType.connectionTimeout,
        );
      final cubit = _cubit(api);
      await cubit.load();
      expect(
        await cubit.markRead('0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'),
        isFalse,
      );
      expect(cubit.state.items.single.unreadCount, 1);
      expect(cubit.state.actionError, NotificationStrings.markReadFailed);
      await cubit.close();
    },
  );

  test('localizes English and Persian content from stored fields', () {
    final notification = appNotificationFromBackend(
      BackendNotification.fromJson(
        _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f'),
      ),
    );
    expect(notification.localizedTitle(const Locale('en')), 'Post approved');
    expect(
      notification.localizedTitle(const Locale('fa', 'IR')),
      'آگهی تأیید شد',
    );
    expect(notification.localizedMessage(const Locale('fa')), 'متن فارسی');
  });

  test('preserves null and unknown targets on mapped notifications', () {
    final none = appNotificationFromBackend(
      BackendNotification.fromJson(
        _item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f', targetType: null),
      ),
    );
    expect(none.targetType, isNull);
    expect(none.targetId, isNull);

    final unknown = AppNotification(
      id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f',
      title: 't',
      message: 'm',
      timeLabel: 'Now',
      targetType: 'warehouse',
      targetId: 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
    );
    expect(NotificationTargetType.known.contains(unknown.targetType), isFalse);
  });

  test('ignores stale list responses after account switch', () async {
    var current = true;
    final api = _Api();
    final cubit = NotificationsCubit(
      ApiNotificationsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => current,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => current,
    );
    await cubit.load();
    current = false;
    api.listResponse = {
      'success': true,
      'data': {
        'items': [_item(id: '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e99')],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
    await cubit.refresh();
    expect(
      cubit.state.items.where(
        (item) => item.id == '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e99',
      ),
      isEmpty,
    );
    await cubit.close();
  });

  test('guest or logged-out account does not request notifications', () async {
    final api = _Api();
    final cubit = NotificationsCubit(
      ApiNotificationsRepository(
        api,
        _Tokens(),
        isCurrentAccount: () => false,
        onUnauthorized: () async {},
      ),
      isCurrentAccount: () => false,
    );
    await Future<void>.delayed(Duration.zero);
    expect(api.gets, isEmpty);
    expect(cubit.state.loading, isFalse);
    await cubit.close();
  });

  test('load failure does not invent sample notifications', () async {
    final api = _Api()
      ..listError = DioException(
        requestOptions: RequestOptions(path: 'notifications'),
        type: DioExceptionType.connectionError,
      );
    final cubit = _cubit(api);
    await cubit.load();
    expect(cubit.state.items, isEmpty);
    expect(cubit.state.error, NotificationStrings.loadFailed);
    await cubit.close();
  });
}
