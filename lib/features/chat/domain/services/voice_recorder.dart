abstract class VoiceRecorder {
  Future<bool> hasPermission();
  Future<void> start();
  Future<String?> stop();
  Future<void> cancel();
  Future<void> discard(String path);
  Future<void> dispose();
}
