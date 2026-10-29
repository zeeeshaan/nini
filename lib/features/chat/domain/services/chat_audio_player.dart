class ChatPlayback {
  const ChatPlayback({
    this.playing = false,
    this.completed = false,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.failed = false,
  });
  final bool playing, completed, failed;
  final Duration position, duration;
}

abstract class ChatAudioPlayer {
  Stream<ChatPlayback> get changes;
  Future<void> load(String path);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);
  Future<void> dispose();
}
