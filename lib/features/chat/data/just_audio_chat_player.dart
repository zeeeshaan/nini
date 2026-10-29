import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'package:nini/features/chat/domain/services/chat_audio_player.dart';

/// One lazily initialized player per conversation prevents overlapping notes.
class JustAudioChatPlayer implements ChatAudioPlayer {
  final _events = StreamController<ChatPlayback>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];
  AudioPlayer? _player;
  Duration _position = Duration.zero, _duration = Duration.zero;
  bool _playing = false, _completed = false, _closed = false;
  AudioPlayer get _audio {
    if (_player != null) return _player!;
    final player = AudioPlayer();
    _player = player;
    _subscriptions.add(
      player.positionStream.listen((value) {
        _position = value;
        _emit();
      }),
    );
    _subscriptions.add(
      player.durationStream.listen((value) {
        _duration = value ?? Duration.zero;
        _emit();
      }),
    );
    _subscriptions.add(
      player.playerStateStream.listen((value) {
        _completed = value.processingState == ProcessingState.completed;
        _playing = value.playing && !_completed;
        _emit();
      }),
    );
    _subscriptions.add(
      player.errorStream.listen((_) {
        if (!_closed) _events.add(const ChatPlayback(failed: true));
      }),
    );
    return player;
  }

  void _emit() {
    if (!_closed) {
      _events.add(
        ChatPlayback(
          playing: _playing,
          completed: _completed,
          position: _position,
          duration: _duration,
        ),
      );
    }
  }

  @override
  Stream<ChatPlayback> get changes => _events.stream;
  @override
  Future<void> load(String path) async {
    await _audio.setFilePath(path);
  }

  @override
  Future<void> play() async {
    // AudioPlayer.play completes only when playback ends; callers need not wait.
    unawaited(
      _audio.play().catchError((Object error) {
        if (!_closed) _events.add(const ChatPlayback(failed: true));
      }),
    );
  }

  @override
  Future<void> pause() async {
    await _player?.pause();
  }

  @override
  Future<void> seek(Duration position) => _audio.seek(position);
  @override
  Future<void> dispose() async {
    _closed = true;
    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    await _player?.dispose();
    await _events.close();
  }
}
