import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/api_client/api_client.dart';
import 'package:hywork/core/network/realtime/realtime_connection_state.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/core/network/realtime/realtime_socket_transport.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/notifications/data/api_notifications_repository.dart';
import 'package:hywork/features/notifications/presentation/cubit/notifications_cubit.dart';

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
  Map<String, dynamic>? listResponse;
  Map<String, dynamic>? unreadResponse;
  Map<String, dynamic>? readResponse;
  Object? listError;
  Object? unreadError;
  int listCalls = 0;
  int unreadCalls = 0;
  Completer<void>? unreadGate;
  Completer<void>? listGate;

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    gets.add(endpoint);
    if (endpoint.startsWith('notifications/unread-count')) {
      unreadCalls++;
      if (unreadGate != null) await unreadGate!.future;
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
    if (listGate != null) await listGate!.future;
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
    if (readResponse != null) {
      return Map<String, dynamic>.from(readResponse!);
    }
    return {
      'success': true,
      'data': {'updated': 1, 'unreadCount': 0},
    };
  }
}

const meId = '66666666-6666-4666-8666-666666666666';
const notificationId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f';
const notificationId2 = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20';
const notificationId3 = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e21';
const notificationId4 = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e22';
const notificationLive1 = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e30';
const notificationLive2 = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e31';

/// Newest-first in-memory page/limit source that shifts when [insertNewest].
///
/// Always serves [pageSize] rows so offset-shift bugs are observable even when
/// the cubit requests a larger client limit.
class _ShiftingNotificationsApi extends ApiClient {
  _ShiftingNotificationsApi(this.newestFirst);

  final List<String> newestFirst;
  final int pageSize = 1;
  final pagesRequested = <int>[];

  void insertNewest(String id) => newestFirst.insert(0, id);

  @override
  Future<Map<String, dynamic>> get(
    String endpoint, {
    required String token,
  }) async {
    if (endpoint.startsWith('notifications/unread-count')) {
      return {
        'success': true,
        'data': {'count': newestFirst.length},
      };
    }
    final uri = Uri.parse(
      endpoint.contains('?') ? 'x://x/$endpoint' : 'x://x/$endpoint',
    );
    final page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
    pagesRequested.add(page);
    final start = (page - 1) * pageSize;
    final slice = start >= newestFirst.length
        ? <String>[]
        : newestFirst.skip(start).take(pageSize).toList(growable: false);
    return {
      'success': true,
      'data': {
        'items': [
          for (final id in slice)
            _item(id: id, createdAt: '2026-11-20T10:00:00.000Z'),
        ],
        'total': newestFirst.length,
        'page': page,
        'limit': pageSize,
        'unreadCount': newestFirst.length,
      },
    };
  }
}

Map<String, dynamic> _item({
  required String id,
  bool isRead = false,
  String createdAt = '2026-11-20T09:00:00.000Z',
}) {
  return {
    'id': id,
    'type': 'post.approved',
    'title': 'Post approved',
    'body': 'Body EN',
    'titleFa': 'آگهی تأیید شد',
    'bodyFa': 'متن فارسی',
    'target': {'type': 'post', 'id': '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99'},
    'data': <String, dynamic>{},
    'isRead': isRead,
    'readAt': null,
    'createdAt': createdAt,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRealtimeSocketTransport transport;
  late RealtimeSocketClient realtime;
  late List<FakeRealtimeSocketTransport> transports;

  Future<void> readySocket({int notifications = 2}) async {
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
      'unread': {'notifications': notifications, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(Duration.zero);
    expect(realtime.state, RealtimeConnectionState.ready);
  }

  NotificationsCubit buildCubit(
    ApiClient api, {
    bool Function()? isCurrentAccount,
  }) {
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
      realtime: realtime,
    );
  }

  setUp(() async {
    await readySocket();
  });

  tearDown(() async {
    await realtime.dispose();
  });

  test('ready event applies notification unread badge', () async {
    final api = _Api()
      ..unreadResponse = {
        'success': true,
        'data': {'count': 9},
      };
    final cubit = buildCubit(api);
    await Future<void>.delayed(Duration.zero);
    transport.push('ready', {
      'userId': meId,
      'unread': {'notifications': 3, 'chats': 1, 'chatMessages': 2},
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.unreadCount, 3);
    expect(cubit.state.badgeCount, 3);
    await cubit.close();
  });

  test('incoming notification:new inserts and dedupes by backend id', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 1,
          'page': 1,
          'limit': 20,
          'unreadCount': 1,
        },
      };
    final cubit = buildCubit(api);
    await cubit.load();
    expect(cubit.state.items, hasLength(1));

    transport.push('notification:new', {
      'notification': _item(
        id: notificationId2,
        createdAt: '2026-11-20T10:00:00.000Z',
      ),
      'unreadCount': 2,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items.map((i) => i.id), [
      notificationId2,
      notificationId,
    ]);
    expect(cubit.state.unreadCount, 2);

    transport.push('notification:new', {
      'notification': _item(
        id: notificationId2,
        createdAt: '2026-11-20T10:00:00.000Z',
      ),
      'unreadCount': 2,
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.items.where((i) => i.id == notificationId2),
      hasLength(1),
    );
    await cubit.close();
  });

  test('notification:new before list load updates badge only', () async {
    final api = _Api();
    api.listError = DioException(
      requestOptions: RequestOptions(path: 'notifications'),
    );
    final cubit = buildCubit(api);
    await Future<void>.delayed(Duration.zero);

    transport.push('notification:new', {
      'notification': _item(id: notificationId2),
      'unreadCount': 6,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.unreadCount, 6);
    expect(cubit.state.items, isEmpty);
    await cubit.close();
  });

  test('stale REST unread-count cannot overwrite newer socket count', () async {
    final api = _Api()
      ..listError = DioException(
        requestOptions: RequestOptions(path: 'notifications'),
      )
      ..unreadResponse = {
        'success': true,
        'data': {'count': 1},
      };
    final gate = Completer<void>();
    api.unreadGate = gate;
    final cubit = buildCubit(api);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    cubit.applySocketUnreadCount(8);
    expect(cubit.state.unreadCount, 8);

    gate.complete();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(cubit.state.unreadCount, 8);
    await cubit.close();
  });

  test('individual and all notification:read update loaded records', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId), _item(id: notificationId2)],
          'total': 2,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = buildCubit(api);
    await cubit.load();

    transport.push('notification:read', {
      'ids': [notificationId],
      'all': false,
      'unreadCount': 1,
    });
    await Future<void>.delayed(Duration.zero);
    expect(
      cubit.state.items.firstWhere((i) => i.id == notificationId).unreadCount,
      0,
    );
    expect(
      cubit.state.items.firstWhere((i) => i.id == notificationId2).unreadCount,
      1,
    );
    expect(cubit.state.unreadCount, 1);

    transport.push('notification:read', {
      'ids': <String>[],
      'all': true,
      'unreadCount': 0,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items.every((i) => i.unreadCount == 0), isTrue);
    expect(cubit.state.unreadCount, 0);
    await cubit.close();
  });

  test(
    'notification created after all-read stays unread until its own read',
    () async {
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: notificationId)],
            'total': 1,
            'page': 1,
            'limit': 20,
            'unreadCount': 1,
          },
        };
      final cubit = buildCubit(api);
      await cubit.load();

      transport.push('notification:read', {
        'ids': <String>[],
        'all': true,
        'unreadCount': 0,
      });
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.unreadCount, 0);

      const newerId = 'dddddddd-dddd-4ddd-8ddd-dddddddddddd';
      transport.push('notification:new', {
        'notification': _item(
          id: newerId,
          createdAt: '2026-11-20T12:00:00.000Z',
        ),
        'unreadCount': 1,
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.items.firstWhere((i) => i.id == newerId).unreadCount,
        greaterThan(0),
      );
      expect(cubit.state.unreadCount, 1);
      await cubit.close();
    },
  );

  test('stale REST list cannot restore confirmed read state', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId, isRead: false)],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      };
    final cubit = buildCubit(api);
    await cubit.load();

    transport.push('notification:read', {
      'ids': [notificationId],
      'all': false,
      'unreadCount': 0,
    });
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.items.single.unreadCount, 0);

    api.listResponse = {
      'success': true,
      'data': {
        'items': [_item(id: notificationId, isRead: false)],
        'total': 1,
        'page': 1,
        'limit': 20,
      },
    };
    await cubit.refresh();
    expect(cubit.state.items.single.unreadCount, 0);
    await cubit.close();
  });

  test(
    'live insert survives in-flight REST refresh without duplicates',
    () async {
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: notificationId)],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        };
      final cubit = buildCubit(api);
      await cubit.load();

      final gate = Completer<void>();
      api.listGate = gate;
      api.listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 2,
          'page': 1,
          'limit': 20,
        },
      };
      final refresh = cubit.refresh();
      await Future<void>.delayed(const Duration(milliseconds: 5));

      transport.push('notification:new', {
        'notification': _item(
          id: notificationId2,
          createdAt: '2026-11-21T10:00:00.000Z',
        ),
        'unreadCount': 2,
      });
      await Future<void>.delayed(Duration.zero);
      expect(
        cubit.state.items.map((i) => i.id).contains(notificationId2),
        isTrue,
      );

      gate.complete();
      await refresh;
      expect(
        cubit.state.items.where((i) => i.id == notificationId2),
        hasLength(1),
      );
      expect(cubit.state.items.first.id, notificationId2);
      await cubit.close();
    },
  );

  test('pagination after live insert does not duplicate ids', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 3,
          'page': 1,
          'limit': 1,
          'unreadCount': 1,
        },
      };
    final cubit = buildCubit(api);
    await cubit.load();
    expect(cubit.state.hasMore, isTrue);

    transport.push('notification:new', {
      'notification': _item(
        id: notificationId2,
        createdAt: '2026-11-21T10:00:00.000Z',
      ),
      'unreadCount': 2,
    });
    await Future<void>.delayed(Duration.zero);

    api.listResponse = {
      'success': true,
      'data': {
        'items': [_item(id: notificationId3)],
        'total': 3,
        'page': 2,
        'limit': 1,
      },
    };
    await cubit.loadMore();
    final ids = cubit.state.items.map((i) => i.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(
      ids,
      containsAll([notificationId, notificationId2, notificationId3]),
    );
    await cubit.close();
  });

  test(
    'offset shift from live inserts does not skip older notifications',
    () async {
      final api = _ShiftingNotificationsApi([
        notificationId,
        notificationId2,
        notificationId3,
        notificationId4,
      ]);
      final cubit = buildCubit(api);
      await cubit.load();
      expect(cubit.state.items.map((i) => i.id), [notificationId]);
      expect(cubit.state.hasMore, isTrue);

      // Two newer rows shift page boundaries: page 2 becomes a duplicate of page 1.
      api.insertNewest(notificationLive1);
      api.insertNewest(notificationLive2);
      transport.push('notification:new', {
        'notification': _item(
          id: notificationLive1,
          createdAt: '2026-11-22T10:00:00.000Z',
        ),
        'unreadCount': 5,
      });
      transport.push('notification:new', {
        'notification': _item(
          id: notificationLive2,
          createdAt: '2026-11-22T11:00:00.000Z',
        ),
        'unreadCount': 6,
      });
      await Future<void>.delayed(Duration.zero);

      await cubit.loadMore();
      final ids = cubit.state.items.map((i) => i.id).toList();
      expect(ids.toSet().length, ids.length);
      // Without duplicate-page continuation, a single loadMore would stop on
      // the shifted duplicate of notificationId and never reach id2.
      expect(ids, contains(notificationId2));
      expect(api.pagesRequested.where((page) => page > 1), isNotEmpty);
      await cubit.close();
    },
  );

  test('reconnection recovery refreshes unread and loaded list', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      }
      ..unreadResponse = {
        'success': true,
        'data': {'count': 1},
      };
    final cubit = buildCubit(api);
    await cubit.load();
    await cubit.refreshUnreadCount();

    transport.completeDisconnect();
    await Future<void>.delayed(Duration.zero);

    api.listResponse = {
      'success': true,
      'data': {
        'items': [
          _item(id: notificationId2, createdAt: '2026-11-21T10:00:00.000Z'),
          _item(id: notificationId),
        ],
        'total': 2,
        'page': 1,
        'limit': 20,
      },
    };
    api.unreadResponse = {
      'success': true,
      'data': {'count': 2},
    };

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(transports.length, greaterThanOrEqualTo(2));
    final next = transports.last;
    next.completeConnect();
    next.push('ready', {
      'userId': meId,
      'unread': {'notifications': 2, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.unreadCount, 2);
    expect(cubit.state.items.map((i) => i.id), contains(notificationId2));
    await cubit.close();
  });

  test('failed recovery keeps previous valid state', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      }
      ..unreadResponse = {
        'success': true,
        'data': {'count': 4},
      };
    final cubit = buildCubit(api);
    await cubit.load();
    await cubit.refreshUnreadCount();
    expect(cubit.state.unreadCount, 4);

    transport.completeDisconnect();
    await Future<void>.delayed(Duration.zero);
    api.listError = DioException(
      requestOptions: RequestOptions(path: 'notifications'),
    );
    api.unreadError = DioException(
      requestOptions: RequestOptions(path: 'notifications/unread-count'),
    );

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    final next = transports.last;
    next.completeConnect();
    next.push('ready', {
      'userId': meId,
      'unread': {'notifications': 4, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(const Duration(milliseconds: 50));

    expect(cubit.state.items.single.id, notificationId);
    expect(cubit.state.unreadCount, 4);
    await cubit.close();
  });

  test('malformed notification payloads do not clear state', () async {
    final api = _Api()
      ..listResponse = {
        'success': true,
        'data': {
          'items': [_item(id: notificationId)],
          'total': 1,
          'page': 1,
          'limit': 20,
        },
      }
      ..unreadResponse = {
        'success': true,
        'data': {'count': 1},
      };
    final cubit = buildCubit(api);
    await cubit.load();
    await cubit.refreshUnreadCount();

    transport.push('notification:new', {'unreadCount': -1});
    transport.push('notification:read', {'unreadCount': 'nope'});
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.items.single.id, notificationId);
    expect(cubit.state.unreadCount, 1);
    await cubit.close();
  });

  test(
    'stale account events ignored and dispose cancels subscription',
    () async {
      var current = true;
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: notificationId)],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        };
      final cubit = NotificationsCubit(
        ApiNotificationsRepository(
          api,
          _Tokens(),
          isCurrentAccount: () => current,
          onUnauthorized: () async {
            current = false;
          },
        ),
        isCurrentAccount: () => current,
        realtime: realtime,
      );
      await cubit.load();
      current = false;
      transport.push('notification:new', {
        'notification': _item(id: notificationId2),
        'unreadCount': 9,
      });
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.items.any((i) => i.id == notificationId2), isFalse);
      expect(cubit.state.unreadCount, isNot(9));
      await cubit.close();
    },
  );

  test(
    'socket then REST markRead reconcile without fabricating unread',
    () async {
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: notificationId)],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        }
        ..readResponse = {
          'success': true,
          'data': {'updated': 1, 'unreadCount': 0},
        };
      final cubit = buildCubit(api);
      await cubit.load();

      transport.push('notification:read', {
        'ids': [notificationId],
        'all': false,
        'unreadCount': 0,
      });
      await Future<void>.delayed(Duration.zero);
      expect(await cubit.markRead(notificationId), isTrue);
      expect(cubit.state.items.single.unreadCount, 0);
      expect(cubit.state.unreadCount, 0);
      await cubit.close();
    },
  );

  test(
    'Firebase-style refresh after socket event does not duplicate',
    () async {
      final api = _Api()
        ..listResponse = {
          'success': true,
          'data': {
            'items': [_item(id: notificationId)],
            'total': 1,
            'page': 1,
            'limit': 20,
          },
        };
      final cubit = buildCubit(api);
      await cubit.load();

      transport.push('notification:new', {
        'notification': _item(
          id: notificationId2,
          createdAt: '2026-11-21T10:00:00.000Z',
        ),
        'unreadCount': 2,
      });
      await Future<void>.delayed(Duration.zero);

      api.listResponse = {
        'success': true,
        'data': {
          'items': [
            _item(id: notificationId2, createdAt: '2026-11-21T10:00:00.000Z'),
            _item(id: notificationId),
          ],
          'total': 2,
          'page': 1,
          'limit': 20,
        },
      };
      api.unreadResponse = {
        'success': true,
        'data': {'count': 2},
      };
      await cubit.refresh();
      await cubit.refreshUnreadCount();

      expect(
        cubit.state.items.where((i) => i.id == notificationId2),
        hasLength(1),
      );
      expect(cubit.state.unreadCount, 2);
      await cubit.close();
    },
  );
}
