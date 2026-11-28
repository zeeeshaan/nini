import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/services/voice_recorder.dart';

enum VoiceRecordingPhase { idle, starting, recording, processing, preview }

class VoiceRecordingState {
  const VoiceRecordingState({
    this.phase = VoiceRecordingPhase.idle,
    this.elapsed = Duration.zero,
    this.path,
    this.error,
  });
  final VoiceRecordingPhase phase;
  final Duration elapsed;
  final String? path, error;
}

class VoiceRecordingCubit extends Cubit<VoiceRecordingState> {
  VoiceRecordingCubit(this.recorder, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now,
      super(const VoiceRecordingState());
  final VoiceRecorder recorder;
  final DateTime Function() _clock;
  Timer? _timer;
  DateTime? _started;
  int _operation = 0;
  bool _closing = false, _stopAfterStart = false;
  bool get active => state.phase != VoiceRecordingPhase.idle;
  bool _valid(int operation) =>
      !_closing && !isClosed && operation == _operation;
  Future<void> start() async {
    if (active || _closing) return;
    final operation = ++_operation;
    _stopAfterStart = false;
    emit(const VoiceRecordingState(phase: VoiceRecordingPhase.starting));
    try {
      final allowed = await recorder.hasPermission();
      if (!_valid(operation)) return;
      if (!allowed) {
        emit(const VoiceRecordingState(error: AppStrings.microphoneDenied));
        return;
      }
      await recorder.start();
      if (!_valid(operation)) {
        try {
          await recorder.cancel();
        } catch (_) {}
        return;
      }
      _started = _clock();
      emit(const VoiceRecordingState(phase: VoiceRecordingPhase.recording));
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_valid(operation) && state.phase == VoiceRecordingPhase.recording) {
          emit(VoiceRecordingState(phase: state.phase, elapsed: _elapsed));
        }
      });
      if (_stopAfterStart) await stop();
    } catch (_) {
      _timer?.cancel();
      try {
        await recorder.cancel();
      } catch (_) {}
      if (_valid(operation)) {
        emit(const VoiceRecordingState(error: AppStrings.recordingFailed));
      }
    }
  }

  Duration get _elapsed => _started == null
      ? Duration.zero
      : Duration(
          milliseconds: _clock()
              .difference(_started!)
              .inMilliseconds
              .clamp(0, 1 << 31),
        );
  Future<void> stop() async {
    if (state.phase == VoiceRecordingPhase.starting) {
      _stopAfterStart = true;
      return;
    }
    if (state.phase != VoiceRecordingPhase.recording || _closing) return;
    final operation = _operation, duration = _elapsed;
    _timer?.cancel();
    emit(
      VoiceRecordingState(
        phase: VoiceRecordingPhase.processing,
        elapsed: duration,
      ),
    );
    try {
      final path = await recorder.stop();
      if (!_valid(operation)) {
        if (path != null) await recorder.discard(path);
        return;
      }
      if (path == null || duration < const Duration(milliseconds: 500)) {
        if (path != null) await recorder.discard(path);
        emit(const VoiceRecordingState(error: AppStrings.recordingTooShort));
      } else {
        emit(
          VoiceRecordingState(
            phase: VoiceRecordingPhase.preview,
            elapsed: duration,
            path: path,
          ),
        );
      }
    } catch (_) {
      _timer?.cancel();
      try {
        await recorder.cancel();
      } catch (_) {}
      if (_valid(operation)) {
        emit(const VoiceRecordingState(error: AppStrings.recordingFailed));
      }
    }
  }

  Future<void> cancel() async {
    if (_closing) return;
    final operation = ++_operation, path = state.path;
    _timer?.cancel();
    emit(const VoiceRecordingState(phase: VoiceRecordingPhase.processing));
    try {
      await recorder.cancel();
      if (path != null) await recorder.discard(path);
    } catch (_) {
      /* Leave the draft unsent even if a native cancellation fails. */
    }
    if (_valid(operation)) emit(const VoiceRecordingState());
  }

  @override
  Future<void> close() async {
    _closing = true;
    _operation++;
    _timer?.cancel();
    try {
      await recorder.cancel();
      if (state.path != null) await recorder.discard(state.path!);
    } catch (_) {}
    try {
      await recorder.dispose();
    } catch (_) {}
    return super.close();
  }
}
