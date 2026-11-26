import 'package:hywork/features/calls/domain/call_session.dart';

/// One service owns one call. Implement with authenticated signaling and RTC.
/// Emit connected only after a remote participant actually joins.
abstract interface class CallService {
  CallSession get current;
  Stream<CallSession> get sessions;
  Future<void> start({required String contactId, required CallType type});
  Future<void> accept();

  /// Must also cancel an in-flight start or accept, and release native media.
  Future<void> end();
  Future<void> setMicrophoneMuted(bool muted);
  Future<void> setSpeakerEnabled(bool enabled);
  Future<void> setCameraEnabled(bool enabled);
  Future<void> switchCamera();
  Future<void> dispose();
}
