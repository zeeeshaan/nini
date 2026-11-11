import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/calls/domain/call_session.dart';
import 'package:nini/features/calls/presentation/pages/call_screen.dart';
import 'package:nini/features/chat/data/device_voice_recorder.dart';
import 'package:nini/features/chat/data/in_memory_chat_repository.dart';
import 'package:nini/features/chat/data/just_audio_chat_player.dart';
import 'package:nini/features/chat/data/local_chat_media_store.dart';
import 'package:nini/features/chat/domain/models/chat_conversation.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/domain/repositories/chat_messages_repository.dart';
import 'package:nini/features/chat/domain/services/chat_audio_player.dart';
import 'package:nini/features/chat/domain/services/chat_media_store.dart';
import 'package:nini/features/chat/domain/services/voice_recorder.dart';
import 'package:nini/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:nini/features/chat/presentation/cubit/voice_playback_cubit.dart';
import 'package:nini/features/chat/presentation/helpers/chat_attachment_flow.dart';
import 'package:nini/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:nini/features/chat/presentation/widgets/conversation/chat_action_dialog.dart';
import 'package:nini/features/chat/presentation/widgets/conversation/conversation_body.dart';
import 'package:nini/features/chat/presentation/widgets/conversation/conversation_header.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';
import 'package:nini/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversation,
    this.subtitle,
    this.onLatestMessageChanged,
    this.repository,
    this.mediaStore,
    this.voiceRecorder,
    this.audioPlayer,
    this.recordingClock,
    this.galleryFactory,
    this.capturePhoto,
    this.headerTitle,
    this.headerBottom,
    this.allowBlocking = true,
  });
  final ChatConversation conversation;
  final String? subtitle;
  final ValueChanged<ChatMessage?>? onLatestMessageChanged;
  final ChatMessagesRepository? repository;
  final ChatMediaStore? mediaStore;
  final VoiceRecorder? voiceRecorder;
  final ChatAudioPlayer? audioPlayer;
  final DateTime Function()? recordingClock;
  final GalleryCubit Function()? galleryFactory;
  final Future<GalleryAttachment?> Function()? capturePhoto;
  final Widget? headerTitle;
  final PreferredSizeWidget? headerBottom;
  final bool allowBlocking;
  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      BlocProvider(
        create: (_) => ConversationCubit(
          conversationId: conversation.id,
          repository: repository ?? InMemoryChatRepository.instance,
          mediaStore: mediaStore ?? LocalChatMediaStore(),
        ),
      ),
      BlocProvider(
        create: (_) => VoiceRecordingCubit(
          voiceRecorder ?? DeviceVoiceRecorder(),
          clock: recordingClock,
        ),
      ),
      BlocProvider(
        create: (_) => VoicePlaybackCubit(audioPlayer ?? JustAudioChatPlayer()),
      ),
    ],
    child: _ConversationView(
      conversation: conversation,
      subtitle: subtitle,
      onLatestMessageChanged: onLatestMessageChanged,
      galleryFactory: galleryFactory,
      capturePhoto: capturePhoto,
      headerTitle: headerTitle,
      headerBottom: headerBottom,
      allowBlocking: allowBlocking,
    ),
  );
}

class _ConversationView extends StatefulWidget {
  const _ConversationView({
    required this.conversation,
    required this.subtitle,
    required this.onLatestMessageChanged,
    this.galleryFactory,
    this.capturePhoto,
    this.headerTitle,
    this.headerBottom,
    this.allowBlocking = true,
  });
  final ChatConversation conversation;
  final String? subtitle;
  final ValueChanged<ChatMessage?>? onLatestMessageChanged;
  final GalleryCubit Function()? galleryFactory;
  final Future<GalleryAttachment?> Function()? capturePhoto;
  final Widget? headerTitle;
  final PreferredSizeWidget? headerBottom;
  final bool allowBlocking;
  @override
  State<_ConversationView> createState() => _ConversationViewState();
}

class _ConversationViewState extends State<_ConversationView>
    with WidgetsBindingObserver, RouteAware {
  final _messageController = TextEditingController(),
      _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();

  PageRoute<dynamic>? _route;
  ConversationCubit get _conversation => context.read<ConversationCubit>();
  VoiceRecordingCubit get _recording => context.read<VoiceRecordingCubit>();
  VoicePlaybackCubit get _playback => context.read<VoicePlaybackCubit>();
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route != _route) {
      entranceRouteObserver.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      if (_route != null) entranceRouteObserver.subscribe(this, _route!);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    entranceRouteObserver.unsubscribe(this);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) return;
    unawaited(_playback.pause());
    if (_recording.state.phase == VoiceRecordingPhase.recording) {
      unawaited(_recording.stop());
    } else if (state == AppLifecycleState.paused &&
        _recording.state.phase == VoiceRecordingPhase.starting) {
      unawaited(_recording.cancel());
    }
  }

  @override
  void didPushNext() {
    unawaited(_playback.pause());
    if (_recording.state.phase == VoiceRecordingPhase.recording) {
      unawaited(_recording.stop());
    }
  }

  void _scrollToNewest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });
  void _sendText() {
    if (_conversation.sendMessage(_messageController.text) != null) {
      _messageController.clear();
    }
  }

  void _keyboard() {
    if (_conversation.state.emojiVisible) _conversation.showEmoji(false);
  }

  Future<void> _toggleEmoji() async {
    if (_conversation.state.emojiVisible) {
      _conversation.showEmoji(false);
      _messageFocusNode.requestFocus();
    } else {
      _messageFocusNode.unfocus();
      await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
      if (mounted) _conversation.showEmoji(true);
    }
  }

  Future<void> _startRecording() async {
    if (!_conversation.canSend) return;
    _messageFocusNode.unfocus();
    _keyboard();
    await _playback.pause();
    if (mounted) await _recording.start();
  }

  Future<void> _cancelRecording() async {
    await _playback.pause();
    if (mounted) await _recording.cancel();
  }

  Future<void> _sendVoice() async {
    final recording = _recording.state;
    if (recording.phase != VoiceRecordingPhase.preview ||
        recording.path == null) {
      return;
    }
    await _playback.pause();
    if (!mounted) return;
    final sent = await _conversation.sendVoice(
      recording.path!,
      recording.elapsed,
    );
    if (mounted && sent != null) await _recording.cancel();
  }

  Future<void> _openGallery(GalleryTab tab) async {
    if (!_conversation.canSend || _recording.active) return;
    _messageFocusNode.unfocus();
    _keyboard();
    await _playback.pause();
    if (!mounted) return;
    final selected = await pickChatGallery(context, tab);
    if (mounted && selected != null && selected.isNotEmpty) {
      await _conversation.sendAttachments(selected);
    }
  }

  Future<void> _openAttachments() async {
    if (_conversation.state.pickingAttachment ||
        !_conversation.canSend ||
        _recording.active) {
      return;
    }
    _conversation.pickingAttachment(true);
    _messageFocusNode.unfocus();
    _keyboard();
    try {
      await _playback.pause();
      if (!mounted) return;
      final result = await pickChatAttachment(
        context,
        galleryFactory: widget.galleryFactory,
        capturePhoto: widget.capturePhoto,
      );
      if (!mounted || result == null || !_conversation.canSend) return;
      if (result.location != null) {
        _conversation.sendLocation(result.location!);
      } else if (result.photos.isNotEmpty) {
        await _conversation.sendAttachments(result.photos);
      }
    } finally {
      if (mounted) _conversation.pickingAttachment(false);
    }
  }

  Future<void> _openCall(CallType type) async {
    if (!_conversation.canSend || _recording.active) return;
    _messageFocusNode.unfocus();
    _keyboard();
    await _playback.pause();
    if (!mounted || !_conversation.canSend) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            CallScreen(conversation: widget.conversation, type: type),
      ),
    );
  }

  Future<void> _deleteSelected() async {
    final count = _conversation.state.selected.length;
    if (count == 0) return;
    final confirmed = await confirmChatAction(
      context,
      title: AppStrings.deleteMessageQuestion(count),
      description: AppStrings.localDeleteHelp,
      confirmLabel: AppStrings.delete,
    );
    if (!mounted || !confirmed) return;
    await _playback.pause();
    if (mounted) await _conversation.deleteSelected();
  }

  Future<void> _action(ConversationAction action) async {
    switch (action) {
      case ConversationAction.select:
        _messageFocusNode.unfocus();
        _keyboard();
        _conversation.startSelection();
      case ConversationAction.clear:
        final confirmed = await confirmChatAction(
          context,
          title: AppStrings.clearConversationQuestion,
          description: AppStrings.localDeleteHelp,
          confirmLabel: AppStrings.delete,
        );
        if (!mounted || !confirmed) return;
        await _playback.pause();
        if (mounted) await _conversation.clearMessages();
      case ConversationAction.block:
        if (!_conversation.state.blocked) {
          final confirmed = await confirmChatAction(
            context,
            title: AppStrings.blockQuestion,
            description: AppStrings.blockHelp,
            confirmLabel: AppStrings.blockPerson,
          );
          if (!mounted || !confirmed) return;
          _conversation.setBlocked(true);
          _messageFocusNode.unfocus();
          _keyboard();
          await _cancelRecording();
        } else {
          _conversation.setBlocked(false);
        }
      case ConversationAction.copy:
        final messages = _conversation.state.messages.where(
          (message) => _conversation.state.selected.contains(message.id),
        );
        if (messages.length == 1 && messages.single.text.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: messages.single.text));
          if (mounted) AppToast.success(context, AppStrings.copiedMessage);
        }
    }
  }

  void _back() {
    if (_conversation.state.emojiVisible) {
      _conversation.showEmoji(false);
    } else if (_conversation.state.selectionMode) {
      _conversation.cancelSelection();
    } else if (_recording.active) {
      unawaited(_cancelRecording());
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ConversationCubit, ConversationState>(
        listenWhen: (before, after) =>
            before.messages != after.messages ||
            before.blocked != after.blocked,
        listener: (context, state) {
          widget.onLatestMessageChanged?.call(_conversation.latestMessage);
          _scrollToNewest();
        },
      ),
      BlocListener<ConversationCubit, ConversationState>(
        listenWhen: (before, after) =>
            after.error != null && before.error != after.error,
        listener: (context, state) => AppToast.error(context, state.error!),
      ),
      BlocListener<VoiceRecordingCubit, VoiceRecordingState>(
        listenWhen: (before, after) =>
            after.error != null && before.error != after.error,
        listener: (context, state) => AppToast.error(context, state.error!),
      ),
      BlocListener<VoicePlaybackCubit, VoicePlaybackState>(
        listenWhen: (before, after) =>
            after.error != null && before.error != after.error,
        listener: (context, state) => AppToast.error(context, state.error!),
      ),
    ],
    child: BlocBuilder<ConversationCubit, ConversationState>(
      builder: (context, conversation) =>
          BlocBuilder<VoiceRecordingCubit, VoiceRecordingState>(
            builder: (context, recording) {
              final selected = conversation.messages.where(
                (message) => conversation.selected.contains(message.id),
              );
              final recordingActive =
                  recording.phase != VoiceRecordingPhase.idle;
              return PopScope(
                canPop:
                    !_conversation.state.emojiVisible &&
                    !conversation.selectionMode &&
                    !recordingActive,
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop &&
                      (_conversation.state.emojiVisible ||
                          conversation.selectionMode ||
                          recordingActive)) {
                    _back();
                  }
                },
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: ConversationHeader(
                      toolbarHeight:
                          (MediaQuery.textScalerOf(context).scale(15) * 1.4 +
                                  MediaQuery.textScalerOf(context).scale(11) *
                                      1.4 +
                                  8)
                              .clamp(70, double.infinity),
                      conversation: widget.conversation,
                      subtitle: widget.subtitle,
                      titleContent: widget.headerTitle,
                      bottom: widget.headerBottom,
                      allowBlocking: widget.allowBlocking,
                      selectionMode: conversation.selectionMode,
                      selectedCount: conversation.selected.length,
                      blocked: conversation.blocked,
                      hasMessages: conversation.messages.isNotEmpty,
                      busy:
                          conversation.sendingMedia ||
                          recordingActive ||
                          _conversation.state.pickingAttachment,
                      canCopy:
                          selected.length == 1 &&
                          selected.single.text.isNotEmpty,
                      onBack: _back,
                      onDelete: _deleteSelected,
                      onSelectAll: _conversation.selectAll,
                      onAction: _action,
                      onVoiceCall: () => _openCall(CallType.voice),
                      onVideoCall: () => _openCall(CallType.video),
                    ),
                    body: ConversationBody(
                      conversation: conversation,
                      pickingAttachment: _conversation.state.pickingAttachment,
                      recording: recording,
                      scrollController: _scrollController,
                      messageController: _messageController,
                      messageFocusNode: _messageFocusNode,
                      emojiVisible: _conversation.state.emojiVisible,
                      onUnblock: () => _conversation.setBlocked(false),
                      onStartSelection: (id) {
                        _messageFocusNode.unfocus();
                        _keyboard();
                        _conversation.startSelection(id);
                      },
                      onSelect: _conversation.toggleSelection,
                      onOpenAttachment: () => unawaited(_playback.pause()),
                      onCancelRecording: _cancelRecording,
                      onStopRecording: _recording.stop,
                      onSendVoice: _sendVoice,
                      onSend: _sendText,
                      onRecord: _startRecording,
                      onEmoji: _toggleEmoji,
                      onKeyboard: _keyboard,
                      onFiles: _openAttachments,
                      onPhotos: () => _openGallery(GalleryTab.photo),
                    ),
                  ),
                ),
              );
            },
          ),
    ),
  );
}
