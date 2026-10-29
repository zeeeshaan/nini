import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/data/local_chat_media_store.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/domain/services/chat_audio_player.dart';
import 'package:nini/features/chat/presentation/cubit/chat_inbox_cubit.dart';
import 'package:nini/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:nini/features/chat/presentation/cubit/voice_playback_cubit.dart';
import 'package:nini/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:nini/features/chat/presentation/pages/conversation_screen.dart';
import 'package:nini/features/chat/presentation/widgets/emoji_panel/chat_emoji_panel.dart';
import 'package:nini/features/chat/presentation/widgets/voice_recording/voice_recording_panel.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/pages/create_post_gallery_screen.dart';

import 'support/chat_fakes.dart';

final class ChatPickedFile extends PlatformFile {
  ChatPickedFile(this.fileName, this.content, {this.broken = false});
  final String fileName;
  final List<int> content;
  final bool broken;
  @override
  String get name => fileName;
  @override
  Uri get uri => Uri.file('/fake/$fileName');
  @override
  Stream<Uint8List> readAsByteStream() => broken
      ? Stream.error(StateError('Unavailable'))
      : Stream.value(Uint8List.fromList(content));
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

ChatConversation contact() => ChatConversation(
  id: 'test',
  name: 'Contact',
  lastMessage: '',
  lastMessageAt: DateTime(2026),
);
ChatMessage sample(String id, {ChatAttachment? attachment}) => ChatMessage(
  id: id,
  conversationId: 'test',
  text: attachment == null ? 'Message $id' : '',
  sentAt: DateTime(2026),
  isMine: true,
  attachment: attachment,
);
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test(
    'Voice recorder handles permission denial, preview, cancel and cleanup',
    () async {
      final recorder = FakeVoiceRecorder()..allowed = false;
      var now = DateTime(2026, 10, 29);
      final cubit = VoiceRecordingCubit(recorder, clock: () => now);
      await cubit.start();
      expect(cubit.state.error, AppStrings.microphoneDenied);
      expect(recorder.starts, 0);
      recorder.allowed = true;
      await cubit.start();
      expect(cubit.state.phase, VoiceRecordingPhase.recording);
      now = now.add(const Duration(seconds: 3));
      await cubit.stop();
      expect(cubit.state.phase, VoiceRecordingPhase.preview);
      expect(cubit.state.elapsed, const Duration(seconds: 3));
      expect(recorder.running, isFalse);
      await cubit.cancel();
      expect(cubit.state.phase, VoiceRecordingPhase.idle);
      expect(recorder.discarded, contains('/fake/draft.m4a'));
      await cubit.close();
      expect(recorder.disposed, isTrue);
    },
  );

  test('Too-short recordings are discarded and late permission cannot start after closing', () async {
    final recorder = FakeVoiceRecorder();
    final cubit = VoiceRecordingCubit(recorder, clock: () => DateTime(2026));
    await cubit.start();
    await cubit.stop();
    expect(cubit.state.error, AppStrings.recordingTooShort);
    expect(recorder.discarded, contains('/fake/draft.m4a'));
    await cubit.close();
    final pending = Completer<bool>();
    final lateRecorder = FakeVoiceRecorder()..permission = pending.future;
    final lateCubit = VoiceRecordingCubit(lateRecorder);
    final start = lateCubit.start();
    await lateCubit.close();
    pending.complete(true);
    await start;
    expect(lateRecorder.starts, 0);
  });

  test(
    'Blocked conversations reject all sends, survive reopening, and unblock',
    () async {
      final repository = InMemoryChatRepository.empty(),
          store = FakeChatMediaStore();
      final cubit = ConversationCubit(
        conversationId: 'test',
        repository: repository,
        mediaStore: store,
      );
      expect(cubit.sendMessage(' hello ')!.text, 'hello');
      cubit.setBlocked(true);
      expect(cubit.sendMessage('must not send'), isNull);
      expect(
        await cubit.sendVoice('/draft', const Duration(seconds: 3)),
        isNull,
      );
      expect(
        await cubit.sendAttachments([
          GalleryAttachment.fromFile(ChatPickedFile('a.pdf', [1])),
        ]),
        isEmpty,
      );
      final reopened = ConversationCubit(
        conversationId: 'test',
        repository: repository,
        mediaStore: store,
      );
      expect(reopened.state.blocked, isTrue);
      reopened.setBlocked(false);
      expect(reopened.sendMessage('new')!.text, 'new');
      expect(repository.getMessages('test'), hasLength(2));
      await cubit.close();
      await reopened.close();
    },
  );

  test('Blocking during attachment preparation cancels the pending send even after unblocking', () async {
    final pending = Completer<List<ChatAttachment>>();
    final store = FakeChatMediaStore()..pending = pending.future;
    final cubit = ConversationCubit(
      conversationId: 'test',
      repository: InMemoryChatRepository.empty(),
      mediaStore: store,
    );
    final sending = cubit.sendAttachments([
      GalleryAttachment.fromFile(ChatPickedFile('a.pdf', [1])),
    ]);
    expect(cubit.state.sendingMedia, isTrue);
    expect(await cubit.sendVoice('/draft', const Duration(seconds: 2)), isNull);
    cubit.setBlocked(true);
    cubit.setBlocked(false);
    const file = ChatAttachment(
      path: '/copied/a.pdf',
      name: 'a.pdf',
      type: ChatAttachmentType.file,
      sizeBytes: 1,
    );
    pending.complete([file]);
    expect(await sending, isEmpty);
    expect(cubit.state.messages, isEmpty);
    expect(store.discarded, [file]);
    expect(cubit.state.sendingMedia, isFalse);
    await cubit.close();
  });

  test('Media errors allow retry; selected deletion updates previews and does not clear other messages', () async {
    final repository = InMemoryChatRepository.empty(),
        store = FakeChatMediaStore()..fail = true;
    final cubit = ConversationCubit(
      conversationId: 'test',
      repository: repository,
      mediaStore: store,
    );
    expect(await cubit.sendVoice('/draft', const Duration(seconds: 2)), isNull);
    expect(cubit.state.error, AppStrings.mediaSendFailed);
    store.fail = false;
    cubit.sendMessage('keep');
    final voice = await cubit.sendVoice('/draft', const Duration(seconds: 2));
    expect(voice!.attachment!.type, ChatAttachmentType.voice);
    final inbox = ChatInboxCubit(
      initialConversations: [contact()],
      repository: repository,
    );
    expect(
      inbox.state.conversations.single.lastMessage,
      AppStrings.voiceMessage,
    );
    cubit.startSelection(voice.id);
    await cubit.deleteSelected();
    inbox.refresh();
    expect(cubit.state.messages.single.text, 'keep');
    expect(inbox.state.conversations.single.lastMessage, 'keep');
    expect(store.discarded, [voice.attachment]);
    await cubit.clearMessages();
    inbox.refresh();
    expect(inbox.state.conversations.single.lastMessage, AppStrings.noMessages);
    expect(repository.getMessages('test'), isEmpty);
    await cubit.close();
    await inbox.close();
  });

  test('Attachment copies keep originals, roll back failed batches, and delete only owned files', () async {
    final root = await Directory.systemTemp.createTemp('nini_chat_media_test_');
    addTearDown(() => root.delete(recursive: true));
    final store = LocalChatMediaStore(directoryProvider: () async => root);
    final input = GalleryAttachment.fromFile(
      ChatPickedFile('notes.pdf', utf8.encode('hello')),
    );
    final copies = await store.prepare([input]);
    expect(await File(copies.single.path).readAsString(), 'hello');
    expect(copies.single.type, ChatAttachmentType.file);
    final original = File('${root.path}/original.m4a');
    await original.writeAsString('audio');
    final voice = await store.prepareVoice(
      original.path,
      const Duration(seconds: 2),
    );
    await store.discard([voice]);
    expect(await original.exists(), isTrue);
    expect(await File(voice.path).exists(), isFalse);
    final before = await Directory('${root.path}/nini_chat_media')
        .list()
        .length;
    await expectLater(
      store.prepare([
        input,
        GalleryAttachment.fromFile(ChatPickedFile('bad.pdf', [], broken: true)),
      ]),
      throwsStateError,
    );
    expect(
      await Directory('${root.path}/nini_chat_media').list().length,
      before,
    );
    await store.discard([
      ChatAttachment(
        path: original.path,
        name: 'external',
        type: ChatAttachmentType.file,
        sizeBytes: 5,
      ),
    ]);
    expect(await original.exists(), isTrue);
  });

  test('One player switches notes, guards concurrent load, and replays completed audio', () async {
    final player = FakeChatAudioPlayer(), pending = Completer<void>();
    player.pendingLoad = pending.future;
    final cubit = VoicePlaybackCubit(player);
    final first = cubit.toggle('one', '/one.m4a');
    await Future<void>.delayed(Duration.zero);
    await cubit.toggle('two', '/two.m4a');
    expect(player.loaded, ['/one.m4a']);
    pending.complete();
    await first;
    expect(cubit.state.audio.playing, isTrue);
    player.pendingLoad = null;
    await cubit.toggle('two', '/two.m4a');
    expect(player.loaded, ['/one.m4a', '/two.m4a']);
    player.events.add(
      const ChatPlayback(
        completed: true,
        position: Duration(seconds: 3),
        duration: Duration(seconds: 3),
      ),
    );
    await cubit.toggle('two', '/two.m4a');
    expect(player.position, Duration.zero);
    await cubit.close();
    expect(player.disposed, isTrue);
  });

  test(
    'Pausing while a voice note loads prevents background autoplay',
    () async {
      final player = FakeChatAudioPlayer();
      final gate = Completer<void>();
      player.pendingLoad = gate.future;
      final cubit = VoicePlaybackCubit(player);
      final playing = cubit.toggle('one', '/one.m4a');
      await Future<void>.delayed(Duration.zero);
      await cubit.pause();
      gate.complete();
      await playing;
      expect(player.plays, 0);
      expect(cubit.state.loading, isFalse);
      await cubit.close();
    },
  );

  for (final dark in [false, true]) {
    for (final width in [320.0, 390.0]) {
      testWidgets(
        'Chat text, emoji, deletion and blocking at $width, dark=$dark',
        (tester) async {
          tester.view.physicalSize = Size(width, 844);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final repository = InMemoryChatRepository.empty();
          final recorder = FakeVoiceRecorder(), audio = FakeChatAudioPlayer();
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.dark : AppTheme.light,
              home: ConversationScreen(
                conversation: contact(),
                repository: repository,
                mediaStore: FakeChatMediaStore(),
                voiceRecorder: recorder,
                audioPlayer: audio,
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.enterText(find.byType(TextField), 'hello');
          await tester.pump();
          await tester.tap(find.byTooltip(AppStrings.sendMessage));
          await tester.pumpAndSettle();
          expect(find.text('hello'), findsOneWidget);
          await tester.longPress(find.text('hello'));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(AppStrings.deleteSelectedMessages));
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppStrings.cancel));
          await tester.pumpAndSettle();
          expect(find.text('hello'), findsOneWidget);
          await tester.tap(find.byTooltip(AppStrings.deleteSelectedMessages));
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppStrings.delete));
          await tester.pumpAndSettle();
          expect(find.text('hello'), findsNothing);
          await tester.tap(find.byTooltip(AppStrings.emoji));
          await tester.pumpAndSettle();
          expect(find.byType(ChatEmojiPanel), findsOneWidget);
          await tester.tap(find.text('😀').first);
          await tester.pumpAndSettle();
          expect(
            tester.widget<TextField>(find.byType(TextField)).controller!.text,
            contains('😀'),
          );
          await tester.tap(find.byTooltip(AppStrings.keyboard));
          await tester.pumpAndSettle();
          await tester.tap(find.byTooltip(AppStrings.chatOptions));
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppStrings.blockPerson));
          await tester.pumpAndSettle();
          await tester.tap(find.text(AppStrings.blockPerson));
          await tester.pumpAndSettle();
          expect(repository.isBlocked('test'), isTrue);
          expect(
            tester.widget<TextField>(find.byType(TextField)).enabled,
            isFalse,
          );
          await tester.tap(find.text(AppStrings.unblockPerson));
          await tester.pumpAndSettle();
          expect(repository.isBlocked('test'), isFalse);
          expect(
            tester.widget<TextField>(find.byType(TextField)).enabled,
            isTrue,
          );
          expect(tester.takeException(), isNull);
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pumpAndSettle();
        },
      );
    }
  }

  testWidgets('Chat gallery returns attachments without opening post details', (
    tester,
  ) async {
    const channel = MethodChannel('com.fluttercandies/photo_manager');
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (_) async => 0,
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        channel,
        null,
      ),
    );
    final repository = InMemoryChatRepository.empty();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: ConversationScreen(
          conversation: contact(),
          repository: repository,
          mediaStore: FakeChatMediaStore(),
          voiceRecorder: FakeVoiceRecorder(),
          audioPlayer: FakeChatAudioPlayer(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.photosVideos));
    await tester.pumpAndSettle();
    final gallery = tester.widget<CreatePostGalleryScreen>(
      find.byType(CreatePostGalleryScreen),
    );
    expect(gallery.nextLabel, AppStrings.sendMessage);
    Navigator.of(tester.element(find.byType(CreatePostGalleryScreen))).pop([
      GalleryAttachment.fromFile(ChatPickedFile('a.pdf', [1])),
    ]);
    await tester.pumpAndSettle();
    expect(
      repository.getMessages('test').single.attachment!.type,
      ChatAttachmentType.file,
    );
    expect(find.text('document.pdf'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('Voice UI records, previews and sends a playable note', (
    tester,
  ) async {
    var now = DateTime(2026, 10, 29);
    final repository = InMemoryChatRepository.empty(),
        recorder = FakeVoiceRecorder(),
        player = FakeChatAudioPlayer();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ConversationScreen(
          conversation: contact(),
          repository: repository,
          mediaStore: FakeChatMediaStore(),
          voiceRecorder: recorder,
          audioPlayer: player,
          recordingClock: () => now,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.recordVoice));
    await tester.pump();
    await tester.pump();
    expect(find.byType(VoiceRecordingPanel), findsOneWidget);
    now = now.add(const Duration(seconds: 3));
    await tester.tap(find.text(AppStrings.stopRecording));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.recordingPreview), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.playVoice));
    await tester.pumpAndSettle();
    expect(player.loaded, ['/fake/draft.m4a']);
    await tester.tap(find.text(AppStrings.sendMessage));
    await tester.pumpAndSettle();
    expect(
      repository.getMessages('test').single.attachment!.type,
      ChatAttachmentType.voice,
    );
    expect(find.byType(VoiceRecordingPanel), findsNothing);
    expect(recorder.discarded, contains('/fake/draft.m4a'));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
