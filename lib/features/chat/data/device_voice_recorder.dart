import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'package:nini/features/chat/domain/services/voice_recorder.dart';

class DeviceVoiceRecorder implements VoiceRecorder {
  AudioRecorder? _instance;
  AudioRecorder get _recorder => _instance ??= AudioRecorder();
  String? _path;
  @override
  Future<bool> hasPermission() => _recorder.hasPermission();
  @override
  Future<void> start() async {
    final root = Platform.isIOS
        ? Directory.systemTemp
        : await getTemporaryDirectory();
    final folder = await Directory(p.join(root.path, 'nini_voice_drafts'))
        .create(recursive: true);
    _path = p.join(folder.path, '${DateTime.now().microsecondsSinceEpoch}.m4a');
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: _path!,
    );
  }

  @override
  Future<String?> stop() async => _instance?.stop();
  @override
  Future<void> cancel() async {
    await _instance?.cancel();
    final path = _path;
    if (path != null) await discard(path);
    _path = null;
  }

  @override
  Future<void> discard(String path) async {
    final file = File(path);
    if (await file.exists()) await file.delete();
    if (_path == path) _path = null;
  }

  @override
  Future<void> dispose() async => _instance?.dispose();
}
