/// Minimal Socket.IO connection lifecycle for HYWORK realtime.
enum RealtimeConnectionState {
  /// No socket and no reconnect pending.
  disconnected,

  /// Transport handshake in progress.
  connecting,

  /// Socket transport is open but `ready` has not been received yet.
  connected,

  /// Authenticated and `ready` received — safe for feature consumers.
  ready,

  /// Waiting to retry after an unexpected drop.
  reconnecting,
}
