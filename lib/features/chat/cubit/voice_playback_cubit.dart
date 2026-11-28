import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/services/chat_audio_player.dart';

class VoicePlaybackState {
  const VoicePlaybackState({
    this.id,
    this.audio = const ChatPlayback(),
    this.loading = false,
    this.error,
  });
  final String? id, error;
  final ChatPlayback audio;
  final bool loading;
}

class VoicePlaybackCubit extends Cubit<VoicePlaybackState> {
  VoicePlaybackCubit(this.player) : super(const VoicePlaybackState()) {
    _subscription = player.changes.listen((audio) {
      if (!isClosed && !_closing) {
        emit(
          VoicePlaybackState(
            id: state.id,
            audio: audio,
            loading: _loading,
            error: audio.failed ? AppStrings.audioPlaybackFailed : null,
          ),
        );
      }
    });
  }
  final ChatAudioPlayer player;
  late final StreamSubscription<ChatPlayback> _subscription;
  bool _loading = false, _closing = false;
  int _intent = 0;
  bool _current(int intent) => !isClosed && !_closing && intent == _intent;

  Future<void> toggle(String id, String path) async {
    if (_loading || isClosed || _closing) return;
    final intent = ++_intent;
    try {
      if (state.id == id && state.audio.playing) {
        await player.pause();
        return;
      }
      if (state.id != id || state.error != null) {
        await player.pause();
        if (!_current(intent)) return;
        _loading = true;
        emit(VoicePlaybackState(id: id, loading: true));
        await player.load(path);
        if (!_current(intent)) return;
        _loading = false;
        emit(VoicePlaybackState(id: id, audio: state.audio));
      }
      if (state.audio.completed) await player.seek(Duration.zero);
      if (_current(intent)) await player.play();
    } catch (_) {
      if (_current(intent)) {
        _loading = false;
        emit(VoicePlaybackState(id: id, error: AppStrings.audioPlaybackFailed));
      }
    }
  }

  /// Invalidates pending loads as well as pausing an already-playing note.
  Future<void> pause() async {
    _intent++;
    _loading = false;
    try {
      await player.pause();
    } catch (_) {}
    if (!isClosed && !_closing) {
      emit(VoicePlaybackState(id: state.id, audio: state.audio));
    }
  }

  Future<void> seek(Duration value) async {
    try {
      await player.seek(value);
    } catch (_) {
      if (!isClosed && !_closing) {
        emit(
          VoicePlaybackState(
            id: state.id,
            audio: state.audio,
            error: AppStrings.audioPlaybackFailed,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    _intent++;
    await _subscription.cancel();
    await player.dispose();
    return super.close();
  }
}
