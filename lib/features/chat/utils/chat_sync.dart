/// Phase 3 REST sync cadences for peer chat (+ Phase C realtime fallback).
///
/// Adjust here when product wants a different polling interval.
abstract final class ChatSync {
  /// Open-conversation message refresh (`GET /chats/{id}/messages`).
  static const messagePollInterval = Duration(seconds: 4);

  /// Bounded permission/metadata refresh while a conversation stays open.
  static const detailsPollInterval = Duration(seconds: 24);

  /// Max extra pages walked with `before` when a poll detects a gap.
  static const maxGapPages = 5;

  /// Clear stale peer typing indicators when no stop event arrives.
  static const peerTypingTimeout = Duration(seconds: 5);
}
