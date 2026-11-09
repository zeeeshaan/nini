enum CallType { voice, video }

enum CallPhase { preparing, ringing, connecting, connected, ended, failed }

enum CallFailure { connection, permission }

class CallSession {
  const CallSession({
    this.phase = CallPhase.preparing,
    this.incoming = false,
    this.microphoneMuted = false,
    this.speakerEnabled = false,
    this.cameraEnabled = true,
    this.frontCamera = true,
    this.connectedAt,
    this.failure,
  });

  final CallPhase phase;
  final bool incoming,
      microphoneMuted,
      speakerEnabled,
      cameraEnabled,
      frontCamera;
  final DateTime? connectedAt;
  final CallFailure? failure;
  bool get finished => phase == CallPhase.ended || phase == CallPhase.failed;

  CallSession copyWith({
    CallPhase? phase,
    bool? microphoneMuted,
    bool? speakerEnabled,
    bool? cameraEnabled,
    bool? frontCamera,
    DateTime? connectedAt,
    CallFailure? failure,
  }) => CallSession(
    phase: phase ?? this.phase,
    incoming: incoming,
    microphoneMuted: microphoneMuted ?? this.microphoneMuted,
    speakerEnabled: speakerEnabled ?? this.speakerEnabled,
    cameraEnabled: cameraEnabled ?? this.cameraEnabled,
    frontCamera: frontCamera ?? this.frontCamera,
    connectedAt: connectedAt ?? this.connectedAt,
    failure: failure ?? this.failure,
  );
}
