import 'package:socket_io_client/socket_io_client.dart' as io;

/// Minimal Socket.IO transport surface for [RealtimeSocketClient].
abstract class RealtimeSocketTransport {
  bool get connected;

  void connect({
    required String origin,
    required String path,
    required String token,
  });

  void disconnect();

  void dispose();

  void on(String event, void Function(dynamic data) handler);

  void off(String event);

  void emit(String event, [dynamic data]);
}

/// Production transport backed by `socket_io_client` (Socket.IO v4).
class SocketIoRealtimeTransport implements RealtimeSocketTransport {
  io.Socket? _socket;

  @override
  bool get connected => _socket?.connected == true;

  @override
  void connect({
    required String origin,
    required String path,
    required String token,
  }) {
    disconnect();
    final socket = io.io(
      origin,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .setPath(path)
          .setAuth({'token': token})
          .disableAutoConnect()
          .disableReconnection()
          .enableForceNew()
          .build(),
    );
    _socket = socket;
    socket.connect();
  }

  @override
  void disconnect() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;
    socket.clearListeners();
    socket.disconnect();
    socket.dispose();
  }

  @override
  void dispose() => disconnect();

  @override
  void on(String event, void Function(dynamic data) handler) {
    _socket?.on(event, handler);
  }

  @override
  void off(String event) {
    _socket?.off(event);
  }

  @override
  void emit(String event, [dynamic data]) {
    final socket = _socket;
    if (socket == null || !socket.connected) return;
    if (data == null) {
      socket.emit(event);
    } else {
      socket.emit(event, data);
    }
  }
}

/// Deterministic transport for unit tests.
class FakeRealtimeSocketTransport implements RealtimeSocketTransport {
  final _handlers = <String, List<void Function(dynamic)>>{};
  final emitted = <MapEntry<String, dynamic>>[];
  bool _connected = false;
  bool disposed = false;
  int connectCalls = 0;
  String? lastOrigin;
  String? lastPath;
  String? lastToken;

  @override
  bool get connected => _connected;

  @override
  void connect({
    required String origin,
    required String path,
    required String token,
  }) {
    connectCalls += 1;
    lastOrigin = origin;
    lastPath = path;
    lastToken = token;
    _connected = false;
  }

  void completeConnect() {
    _connected = true;
    _emitLocal('connect', null);
  }

  void completeConnectError(dynamic error) {
    _connected = false;
    _emitLocal('connect_error', error);
  }

  void completeDisconnect([dynamic reason]) {
    _connected = false;
    _emitLocal('disconnect', reason);
  }

  void push(String event, dynamic data) => _emitLocal(event, data);

  void _emitLocal(String event, dynamic data) {
    final handlers = List<void Function(dynamic)>.from(_handlers[event] ?? []);
    for (final handler in handlers) {
      handler(data);
    }
  }

  @override
  void disconnect() {
    _connected = false;
  }

  @override
  void dispose() {
    disposed = true;
    _handlers.clear();
    disconnect();
  }

  @override
  void on(String event, void Function(dynamic data) handler) {
    _handlers.putIfAbsent(event, () => []).add(handler);
  }

  @override
  void off(String event) {
    _handlers.remove(event);
  }

  @override
  void emit(String event, [dynamic data]) {
    emitted.add(MapEntry(event, data));
  }
}
