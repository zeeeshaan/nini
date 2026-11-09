import 'dart:async';

import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/domain/call_service.dart';

/// Interactive UI preview only. Does not capture media or contact another user.
class PreviewCallService implements CallService {
  PreviewCallService({DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;
  final DateTime Function() _clock;
  final _sessions = StreamController<CallSession>.broadcast(sync: true);
  CallSession _current = const CallSession();
  @override
  CallSession get current => _current;
  @override
  Stream<CallSession> get sessions => _sessions.stream;
  void _update(CallSession value) {
    if (_sessions.isClosed || _current.finished) return;
    _current = value;
    _sessions.add(value);
  }

  @override
  Future<void> start({
    required String contactId,
    required CallType type,
  }) async {
    _update(
      type == CallType.voice
          ? const CallSession(phase: CallPhase.ringing, incoming: true)
          : CallSession(
              phase: CallPhase.connected,
              connectedAt: _clock(),
              speakerEnabled: true,
            ),
    );
  }

  @override
  Future<void> accept() async {
    if (_current.phase != CallPhase.ringing) return;
    _update(
      _current.copyWith(phase: CallPhase.connected, connectedAt: _clock()),
    );
  }

  @override
  Future<void> end() async =>
      _update(_current.copyWith(phase: CallPhase.ended));
  @override
  Future<void> setMicrophoneMuted(bool muted) async =>
      _update(_current.copyWith(microphoneMuted: muted));
  @override
  Future<void> setSpeakerEnabled(bool enabled) async =>
      _update(_current.copyWith(speakerEnabled: enabled));
  @override
  Future<void> setCameraEnabled(bool enabled) async =>
      _update(_current.copyWith(cameraEnabled: enabled));
  @override
  Future<void> switchCamera() async =>
      _update(_current.copyWith(frontCamera: !_current.frontCamera));
  @override
  Future<void> dispose() => _sessions.close();
}
