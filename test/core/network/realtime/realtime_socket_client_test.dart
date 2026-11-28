import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hywork/core/network/realtime/realtime_connection_state.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/core/network/realtime/realtime_socket_config.dart';
import 'package:hywork/core/network/realtime/realtime_socket_transport.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';

class _Tokens extends SecureTokenStore {
  _Tokens([this.value = 'user-token']);
  String? value;

  @override
  Future<String?> getToken() async => value;
}

class _FixedRandom implements math.Random {
  @override
  int nextInt(int max) => 0;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

const _userId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e1f';
const _chatId = '3c2b1a09-8f7e-4d6c-9b5a-4e3d2c1b0a99';
const _messageId = '0193f0a1-2b3c-7d4e-8f50-6a7b8c9d0e20';

void main() {
  late FakeRealtimeSocketTransport transport;
  late bool accountCurrent;
  late RealtimeSocketClient client;
  late List<FakeRealtimeSocketTransport> created;

  RealtimeSocketClient buildClient() {
    created = <FakeRealtimeSocketTransport>[];
    return RealtimeSocketClient(
      tokenStore: _Tokens(),
      isCurrentAccount: () => accountCurrent,
      accountRevision: 1,
      userId: _userId,
      apiBaseUrl: 'http://35.154.187.106/api',
      transportFactory: () {
        transport = FakeRealtimeSocketTransport();
        created.add(transport);
        return transport;
      },
      maxReconnectAttempts: 3,
      random: _FixedRandom(),
    );
  }

  setUp(() {
    accountCurrent = true;
    client = buildClient();
  });

  tearDown(() async {
    await client.dispose();
  });

  Future<void> connectReady([RealtimeSocketClient? target]) async {
    final active = target ?? client;
    await active.connect();
    expect(transport.connectCalls, 1);
    expect(transport.lastPath, RealtimeSocketConfig.path);
    expect(transport.lastToken, 'user-token');
    expect(transport.lastOrigin, 'http://35.154.187.106');
    transport.completeConnect();
    transport.push('ready', {
      'userId': _userId,
      'unread': {'notifications': 0, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(Duration.zero);
    expect(active.state, RealtimeConnectionState.ready);
  }

  test('connects with auth token and becomes ready', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await connectReady();
    expect(events.whereType<RealtimeReady>(), hasLength(1));
    await sub.cancel();
  });

  test('prevents duplicate concurrent connections', () async {
    await client.connect();
    await client.connect();
    expect(created, hasLength(1));
    expect(created.single.connectCalls, 1);
  });

  test('authentication failure disconnects without reconnect', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await client.connect();
    transport.completeConnectError('session_expired');
    await Future<void>.delayed(Duration.zero);
    expect(client.state, RealtimeConnectionState.disconnected);
    expect(
      events.whereType<RealtimeAuthFailure>().single.code,
      'session_expired',
    );
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(created, hasLength(1));
    await sub.cancel();
  });

  test('ignores feature events until ready', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await client.connect();
    transport.completeConnect();
    transport.push('chat:typing', {
      'conversationId': _chatId,
      'userId': _userId,
      'typing': true,
    });
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<RealtimeChatTyping>(), isEmpty);

    transport.push('ready', {
      'userId': _userId,
      'unread': {'notifications': 1, 'chats': 0, 'chatMessages': 0},
    });
    transport.push('chat:typing', {
      'conversationId': _chatId,
      'userId': _userId,
      'typing': true,
    });
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<RealtimeChatTyping>(), hasLength(1));
    await sub.cancel();
  });

  test('sendTyping is rate-limited to two seconds', () async {
    await connectReady();
    client.sendTyping(conversationId: _chatId, typing: true);
    client.sendTyping(conversationId: _chatId, typing: true);
    expect(transport.emitted, hasLength(1));
    expect(transport.emitted.single.key, 'chat:typing');
  });

  test(
    'typing-stop is coalesced until the two-second rate limit elapses',
    () async {
      await connectReady();
      client.sendTyping(conversationId: _chatId, typing: true);
      client.sendTyping(conversationId: _chatId, typing: false);
      expect(transport.emitted, hasLength(1));
      expect(transport.emitted.single.value['typing'], isTrue);

      await Future<void>.delayed(const Duration(seconds: 2));
      expect(transport.emitted, hasLength(2));
      expect(transport.emitted.last.value['typing'], isFalse);
    },
  );

  test('pending typing-stop is cancelled on disconnect', () async {
    await connectReady();
    client.sendTyping(conversationId: _chatId, typing: true);
    client.sendTyping(conversationId: _chatId, typing: false);
    expect(transport.emitted, hasLength(1));
    await client.disconnect();
    await Future<void>.delayed(const Duration(seconds: 2));
    expect(transport.emitted, hasLength(1));
  });

  test('unexpected disconnect reconnects and emits recovery', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await connectReady();

    transport.completeDisconnect('transport close');
    await Future<void>.delayed(Duration.zero);
    expect(client.state, RealtimeConnectionState.reconnecting);

    await Future<void>.delayed(const Duration(milliseconds: 1100));
    expect(created.length, greaterThanOrEqualTo(2));
    final next = created.last;
    next.completeConnect();
    next.push('ready', {
      'userId': _userId,
      'unread': {'notifications': 0, 'chats': 0, 'chatMessages': 0},
    });
    await Future<void>.delayed(Duration.zero);
    expect(client.state, RealtimeConnectionState.ready);
    expect(events.whereType<RealtimeRecovered>(), isNotEmpty);
    await sub.cancel();
  });

  test('account switch drops stale events and cancels reconnect', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await connectReady();
    accountCurrent = false;
    await client.disconnect();
    transport.push('chat:message', {
      'conversationId': _chatId,
      'message': {
        'id': _messageId,
        'conversationId': _chatId,
        'senderId': _userId,
        'isMine': false,
        'type': 'text',
        'text': 'stale',
        'deleted': false,
        'createdAt': '2026-11-20T09:00:00.000Z',
      },
      'unread': 1,
    });
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<RealtimeChatMessage>(), isEmpty);
    expect(client.state, RealtimeConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(created, hasLength(1));
    await sub.cancel();
  });

  test('background disconnects; foreground connects', () async {
    await connectReady();
    client.setAppForeground(false);
    expect(client.state, RealtimeConnectionState.disconnected);

    final before = created.length;
    client.setAppForeground(true);
    await Future<void>.delayed(Duration.zero);
    expect(created.length, greaterThan(before));
  });

  test('dispose cancels reconnect and closes resources', () async {
    await client.connect();
    transport.completeDisconnect('x');
    await client.dispose();
    expect(client.state, RealtimeConnectionState.disconnected);
    await Future<void>.delayed(const Duration(milliseconds: 1200));
    expect(created, hasLength(1));
  });

  test('origin helper strips /api path', () {
    expect(
      RealtimeSocketConfig.originFromApiBaseUrl('http://35.154.187.106/api'),
      'http://35.154.187.106',
    );
    expect(
      RealtimeSocketConfig.originFromApiBaseUrl('https://api.hywork.app/api/'),
      'https://api.hywork.app',
    );
  });

  test('malformed events are surfaced without crashing', () async {
    final events = <RealtimeEvent>[];
    final sub = client.events.listen(events.add);
    await connectReady();
    transport.push('ready', {'userId': 'bad'});
    await Future<void>.delayed(Duration.zero);
    expect(events.whereType<RealtimeMalformedEvent>(), isNotEmpty);
    await sub.cancel();
  });
}
