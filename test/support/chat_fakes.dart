import 'dart:async';

import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/chat/domain/services/chat_audio_player.dart';
import 'package:nini/features/chat/domain/services/chat_media_store.dart';
import 'package:nini/features/chat/domain/services/voice_recorder.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

class FakeChatMediaStore implements ChatMediaStore {
  Future<List<ChatAttachment>>? pending;
  bool fail = false;
  final discarded = <ChatAttachment>[];
  @override
  Future<List<ChatAttachment>> prepare(List<GalleryAttachment> selected) async {
    if (fail) throw StateError('Copy failed');
    return pending ??
        [
          const ChatAttachment(
            path: '/fake/document.pdf',
            name: 'document.pdf',
            type: ChatAttachmentType.file,
            sizeBytes: 12,
          ),
        ];
  }

  @override
  Future<ChatAttachment> prepareVoice(String path, Duration duration) async {
    if (fail) throw StateError('Copy failed');
    return ChatAttachment(
      path: '/fake/sent-voice.m4a',
      name: 'voice.m4a',
      type: ChatAttachmentType.voice,
      sizeBytes: 100,
      duration: duration,
    );
  }

  @override
  Future<void> discard(Iterable<ChatAttachment> attachments) async {
    discarded.addAll(attachments);
  }
}

class FakeVoiceRecorder implements VoiceRecorder {
  bool allowed = true, running = false, disposed = false, failStart = false;
  Future<bool>? permission;
  int starts = 0, cancellations = 0;
  final discarded = <String>[];
  @override
  Future<bool> hasPermission() async => permission ?? allowed;
  @override
  Future<void> start() async {
    if (failStart) throw StateError('No microphone');
    starts++;
    running = true;
  }

  @override
  Future<String?> stop() async {
    running = false;
    return '/fake/draft.m4a';
  }

  @override
  Future<void> cancel() async {
    running = false;
    cancellations++;
  }

  @override
  Future<void> discard(String path) async {
    discarded.add(path);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

class FakeChatAudioPlayer implements ChatAudioPlayer {
  final events = StreamController<ChatPlayback>.broadcast(sync: true);
  final loaded = <String>[];
  bool disposed = false;
  int pauses = 0, plays = 0;
  Duration position = Duration.zero;
  Future<void>? pendingLoad;
  @override
  Stream<ChatPlayback> get changes => events.stream;
  @override
  Future<void> load(String path) async {
    loaded.add(path);
    events.add(const ChatPlayback(duration: Duration(seconds: 3)));
    await pendingLoad;
  }

  @override
  Future<void> play() async {
    plays++;
    events.add(
      ChatPlayback(
        playing: true,
        position: position,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Future<void> pause() async {
    pauses++;
    events.add(
      ChatPlayback(position: position, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Future<void> seek(Duration value) async {
    position = value;
    events.add(
      ChatPlayback(position: position, duration: const Duration(seconds: 3)),
    );
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await events.close();
  }
}
