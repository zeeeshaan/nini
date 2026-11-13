import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/domain/call_service.dart';

class CallState {
  const CallState({
    required this.session,
    this.elapsed = Duration.zero,
    this.busy = false,
    this.controlError,
    this.optionsVisible = false,
  });
  final CallSession session;
  final Duration elapsed;
  final bool busy;
  final bool optionsVisible;
  final String? controlError;
  CallState copyWith({
    CallSession? session,
    Duration? elapsed,
    bool? busy,
    String? controlError,
    bool? optionsVisible,
  }) => CallState(
    session: session ?? this.session,
    elapsed: elapsed ?? this.elapsed,
    busy: busy ?? this.busy,
    controlError: controlError,
    optionsVisible: optionsVisible ?? this.optionsVisible,
  );
}

class CallCubit extends Cubit<CallState> {
  CallCubit(this.service, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(CallState(session: service.current)) {
    _subscription = service.sessions.listen(
      _update,
      onError: (Object error) {
        if (!isClosed && !_ending) {
          _update(
            state.session.copyWith(
              phase: CallPhase.failed,
              failure: CallFailure.connection,
            ),
          );
        }
      },
    );
    _update(service.current);
  }
  final CallService service;
  final DateTime Function() _clock;
  late final StreamSubscription<CallSession> _subscription;
  Timer? _timer;
  bool _ending = false, _controlPending = false;

  void _update(CallSession session) {
    if (isClosed || _ending || state.session.finished) return;
    _timer?.cancel();
    emit(
      state.copyWith(
        session: session,
        elapsed: _elapsed(session),
        busy: _controlPending,
      ),
    );
    if (session.phase == CallPhase.connected && session.connectedAt != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!isClosed) {
          emit(
            state.copyWith(
              session: state.session,
              busy: state.busy,
              elapsed: _elapsed(state.session),
            ),
          );
        }
      });
    }
  }

  Duration _elapsed(CallSession session) {
    if (session.connectedAt == null) return Duration.zero;
    final elapsed = _clock().difference(session.connectedAt!);
    return elapsed.isNegative ? Duration.zero : elapsed;
  }

  void toggleOptions() => emit(
    state.copyWith(
      optionsVisible: !state.optionsVisible,
      controlError: state.controlError,
    ),
  );

  Future<void> start(String contactId, CallType type) async {
    if (_ending || state.session.finished || state.session.incoming) return;
    try {
      await service.start(contactId: contactId, type: type);
    } catch (_) {
      _update(
        state.session.copyWith(
          phase: CallPhase.failed,
          failure: CallFailure.connection,
        ),
      );
    }
  }

  Future<void> accept() => _control(service.accept);
  Future<void> toggleMicrophone() => _control(
    () => service.setMicrophoneMuted(!state.session.microphoneMuted),
  );
  Future<void> toggleSpeaker() =>
      _control(() => service.setSpeakerEnabled(!state.session.speakerEnabled));
  Future<void> toggleCamera() =>
      _control(() => service.setCameraEnabled(!state.session.cameraEnabled));
  Future<void> switchCamera() => _control(service.switchCamera);
  Future<void> _control(Future<void> Function() action) async {
    if (_ending || isClosed || _controlPending || state.session.finished) {
      return;
    }
    _controlPending = true;
    emit(
      state.copyWith(
        session: state.session,
        elapsed: state.elapsed,
        busy: true,
      ),
    );
    String? error;
    try {
      await action();
    } catch (_) {
      error = AppStrings.callControlFailed;
    }
    _controlPending = false;
    if (!isClosed && !_ending) {
      emit(
        state.copyWith(
          session: state.session,
          elapsed: state.elapsed,
          controlError: error,
          busy: false,
        ),
      );
    }
  }

  Future<void> end() async {
    if (_ending) return;
    _ending = true;
    _timer?.cancel();
    if (!isClosed) {
      emit(
        state.copyWith(
          session: state.session.copyWith(phase: CallPhase.ended),
          busy: false,
          elapsed: state.elapsed,
        ),
      );
    }
    try {
      await service.end();
    } catch (_) {
      /* Still close the local call. */
    }
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _subscription.cancel();
    await end();
    try {
      await service.dispose();
    } finally {
      await super.close();
    }
  }
}
