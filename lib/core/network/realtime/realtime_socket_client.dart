import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:hywork/core/network/realtime/realtime_connection_state.dart';
import 'package:hywork/core/network/realtime/realtime_event_parser.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_config.dart';
import 'package:hywork/core/network/realtime/realtime_socket_transport.dart';
import 'package:hywork/core/security/secure_token/secure_token.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';

/// Shared authenticated Socket.IO client for one active HYWORK account.
///
/// Phase C chat Cubits subscribe to [events]; notification consumers wait for
/// Phase D. Prefer one account-scoped instance from app providers.
class RealtimeSocketClient {
  RealtimeSocketClient({
    required this.tokenStore,
    required this.isCurrentAccount,
    required this.accountRevision,
    this.userId,
    RealtimeSocketTransport Function()? transportFactory,
    this.apiBaseUrl,
    this.maxReconnectAttempts = 8,
    math.Random? random,
  }) : _transportFactory = transportFactory ?? SocketIoRealtimeTransport.new,
       _random = random ?? math.Random();

  final SecureTokenStore tokenStore;
  final bool Function() isCurrentAccount;
  final int accountRevision;
  final String? userId;
  final RealtimeSocketTransport Function() _transportFactory;
  final String? apiBaseUrl;
  final int maxReconnectAttempts;
  final math.Random _random;

  final _stateController =
      StreamController<RealtimeConnectionState>.broadcast();
  final _eventController = StreamController<RealtimeEvent>.broadcast();

  RealtimeSocketTransport? _transport;
  RealtimeConnectionState _state = RealtimeConnectionState.disconnected;
  Timer? _reconnectTimer;
  int _generation = 0;
  int _reconnectAttempt = 0;
  bool _disposed = false;
  bool _appForeground = true;
  bool _manualDisconnect = false;
  bool _connecting = false;
  static const _typingMinInterval = Duration(seconds: 2);

  DateTime? _lastTypingAt;
  String? _lastTypingConversationId;
  bool? _lastTypingValue;
  Timer? _pendingTypingStop;
  String? _pendingTypingStopConversationId;
  int _pendingTypingStopGeneration = 0;

  RealtimeConnectionState get state => _state;
  Stream<RealtimeConnectionState> get connectionStates =>
      _stateController.stream;
  Stream<RealtimeEvent> get events => _eventController.stream;
  bool get isReady => _state == RealtimeConnectionState.ready;

  /// Connect using the current auth token when the account is still active.
  Future<void> connect() async {
    if (_disposed || !isCurrentAccount() || !_appForeground) return;
    if (_connecting ||
        _state == RealtimeConnectionState.connecting ||
        _state == RealtimeConnectionState.ready ||
        _state == RealtimeConnectionState.connected) {
      return;
    }

    _manualDisconnect = false;
    _connecting = true;
    final generation = ++_generation;
    _setState(
      _reconnectAttempt == 0
          ? RealtimeConnectionState.connecting
          : RealtimeConnectionState.reconnecting,
    );

    try {
      final token = await _readToken();
      if (_disposed ||
          generation != _generation ||
          !isCurrentAccount() ||
          !_appForeground ||
          token == null) {
        if (!_disposed && generation == _generation) {
          _setState(RealtimeConnectionState.disconnected);
        }
        return;
      }

      final origin = RealtimeSocketConfig.originFromApiBaseUrl(apiBaseUrl);
      final transport = _transportFactory();
      _transport?.dispose();
      _transport = transport;
      _bindTransport(transport, generation);
      transport.connect(
        origin: origin,
        path: RealtimeSocketConfig.path,
        token: token,
      );
    } catch (error, stack) {
      debugPrint('RealtimeSocketClient.connect failed: $error\n$stack');
      if (!_disposed && generation == _generation) {
        _setState(RealtimeConnectionState.disconnected);
        _scheduleReconnect(generation);
      }
    } finally {
      if (generation == _generation) _connecting = false;
    }
  }

  /// App foreground/background. Background drops the socket; push covers offline.
  void setAppForeground(bool foreground) {
    if (_disposed) return;
    _appForeground = foreground;
    if (!foreground) {
      _cancelPendingTypingStop();
      _cancelReconnect();
      _manualDisconnect = true;
      _tearDownTransport();
      _setState(RealtimeConnectionState.disconnected);
      return;
    }
    if (isCurrentAccount()) {
      unawaited(connect());
    }
  }

  /// Documented app→server typing signal (at most every 2 seconds).
  ///
  /// No backend exception for typing-stop is documented, so stop events that
  /// would violate the rate limit are coalesced into one delayed emit. Pending
  /// stops are cancelled on disconnect, logout, background, and dispose so they
  /// never replay after the socket is gone.
  /// Emits `chat:typing`. When [force] is true, bypasses the 2s start throttle
  /// (used after socket ready / heartbeat replay).
  void sendTyping({
    required String conversationId,
    required bool typing,
    bool force = false,
  }) {
    if (_disposed || !isReady || !isCurrentAccount()) return;
    if (!ProfileCategory.isBackendId(conversationId)) return;

    if (typing) {
      _cancelPendingTypingStop();
      final now = DateTime.now();
      final throttled =
          _lastTypingConversationId == conversationId &&
          _lastTypingValue == true &&
          _lastTypingAt != null &&
          now.difference(_lastTypingAt!) < _typingMinInterval;
      if (!force && throttled) {
        return;
      }
      _emitTyping(conversationId: conversationId, typing: true);
      return;
    }

    // Stop — only meaningful after a start for this conversation.
    if (_lastTypingConversationId != conversationId ||
        _lastTypingValue != true) {
      if (_pendingTypingStopConversationId == conversationId) {
        _cancelPendingTypingStop();
      }
      return;
    }

    final now = DateTime.now();
    final elapsed = _lastTypingAt == null
        ? _typingMinInterval
        : now.difference(_lastTypingAt!);
    if (elapsed >= _typingMinInterval) {
      _cancelPendingTypingStop();
      _emitTyping(conversationId: conversationId, typing: false);
      return;
    }

    final wait = _typingMinInterval - elapsed;
    final generation = _generation;
    _pendingTypingStopConversationId = conversationId;
    _pendingTypingStopGeneration = generation;
    _pendingTypingStop?.cancel();
    _pendingTypingStop = Timer(wait, () {
      _pendingTypingStop = null;
      _pendingTypingStopConversationId = null;
      if (_disposed ||
          !isReady ||
          !isCurrentAccount() ||
          generation != _generation ||
          generation != _pendingTypingStopGeneration) {
        return;
      }
      if (_lastTypingConversationId != conversationId ||
          _lastTypingValue != true) {
        return;
      }
      _emitTyping(conversationId: conversationId, typing: false);
    });
  }

  void _emitTyping({required String conversationId, required bool typing}) {
    _lastTypingConversationId = conversationId;
    _lastTypingValue = typing;
    _lastTypingAt = DateTime.now();
    _transport?.emit(RealtimeEventName.chatTyping, {
      'conversationId': conversationId,
      'typing': typing,
    });
  }

  void _cancelPendingTypingStop() {
    _pendingTypingStop?.cancel();
    _pendingTypingStop = null;
    _pendingTypingStopConversationId = null;
    _pendingTypingStopGeneration = 0;
  }

  Future<void> disconnect() async {
    if (_disposed) return;
    _manualDisconnect = true;
    _cancelPendingTypingStop();
    _cancelReconnect();
    _generation++;
    _reconnectAttempt = 0;
    _tearDownTransport();
    _setState(RealtimeConnectionState.disconnected);
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await disconnect();
    await _stateController.close();
    await _eventController.close();
  }

  void _bindTransport(RealtimeSocketTransport transport, int generation) {
    transport.on('connect', (_) {
      if (!_isLive(generation)) return;
      _setState(RealtimeConnectionState.connected);
    });
    transport.on('connect_error', (error) {
      if (!_isLive(generation)) return;
      final auth = RealtimeEventParser.parseConnectError(error);
      if (auth != null) {
        _publish(auth);
        _manualDisconnect = true;
        _cancelReconnect();
        _tearDownTransport();
        _setState(RealtimeConnectionState.disconnected);
        return;
      }
      _tearDownTransport();
      _setState(RealtimeConnectionState.disconnected);
      _scheduleReconnect(generation);
    });
    transport.on('disconnect', (_) {
      if (!_isLive(generation)) return;
      final wasReady =
          _state == RealtimeConnectionState.ready ||
          _state == RealtimeConnectionState.connected;
      _tearDownTransport();
      _setState(RealtimeConnectionState.disconnected);
      if (!_manualDisconnect && wasReady) {
        _scheduleReconnect(generation);
      }
    });

    for (final name in RealtimeEventName.serverEvents) {
      transport.on(name, (data) {
        if (!_isLive(generation)) return;
        final event = RealtimeEventParser.parse(name, data);
        if (event is RealtimeReady) {
          if (userId != null && event.userId != userId) {
            _publish(
              RealtimeMalformedEvent(
                name: name,
                error: const FormatException('ready userId mismatch.'),
              ),
            );
            return;
          }
          final recovered =
              _reconnectAttempt > 0 ||
              _state == RealtimeConnectionState.reconnecting;
          _reconnectAttempt = 0;
          _setState(RealtimeConnectionState.ready);
          _publish(event);
          if (recovered) _publish(const RealtimeRecovered());
          return;
        }
        if (_state != RealtimeConnectionState.ready &&
            event is! RealtimeMalformedEvent &&
            event is! RealtimeUnknownEvent) {
          // Ignore feature events until authenticated `ready`.
          return;
        }
        _publish(event);
      });
    }
  }

  Future<String?> _readToken() async {
    final token = (await tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    if (token == null ||
        token.isEmpty ||
        token.contains(RegExp(r'[\r\n]')) ||
        !isCurrentAccount()) {
      return null;
    }
    return token;
  }

  void _scheduleReconnect(int generation) {
    if (_disposed ||
        _manualDisconnect ||
        !_appForeground ||
        !isCurrentAccount() ||
        generation != _generation) {
      return;
    }
    if (_reconnectAttempt >= maxReconnectAttempts) {
      _setState(RealtimeConnectionState.disconnected);
      return;
    }
    _cancelReconnect();
    final attempt = _reconnectAttempt;
    _reconnectAttempt += 1;
    final baseMs = math.min(30000, 1000 * (1 << math.min(attempt, 4)));
    final jitterMs = _random.nextInt(250);
    _setState(RealtimeConnectionState.reconnecting);
    _reconnectTimer = Timer(Duration(milliseconds: baseMs + jitterMs), () {
      if (!_isLive(generation)) return;
      unawaited(connect());
    });
  }

  void _cancelReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }

  void _tearDownTransport() {
    final transport = _transport;
    _transport = null;
    transport?.dispose();
  }

  bool _isLive(int generation) =>
      !_disposed && generation == _generation && isCurrentAccount();

  void _setState(RealtimeConnectionState next) {
    if (_disposed || _state == next) return;
    _state = next;
    if (!_stateController.isClosed) _stateController.add(next);
  }

  void _publish(RealtimeEvent event) {
    if (_disposed || _eventController.isClosed) return;
    _eventController.add(event);
  }
}
