import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/calls/domain/call_session.dart';
import 'package:hywork/features/calls/presentation/pages/call_screen.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/models/chat_message.dart';
import 'package:hywork/features/chat/services/chat_audio_player.dart';
import 'package:hywork/features/chat/services/chat_media_store.dart';
import 'package:hywork/features/chat/services/voice_recorder.dart';
import 'package:hywork/features/chat/cubit/conversation_cubit.dart';
import 'package:hywork/features/chat/cubit/voice_playback_cubit.dart';
import 'package:hywork/features/chat/cubit/voice_recording_cubit.dart';
import 'package:hywork/features/chat/utils/active_conversation_registration.dart';
import 'package:hywork/features/chat/utils/chat_attachment_flow.dart';
import 'package:hywork/features/chat/utils/chat_composer_draft.dart';
import 'package:hywork/features/chat/utils/conversation_bloc_scope.dart';
import 'package:hywork/features/chat/widgets/chat_dialogs/chat_action_dialog.dart';
import 'package:hywork/features/chat/widgets/chat_dialogs/chat_message_delete_sheet.dart';
import 'package:hywork/features/chat/widgets/conversation_body/conversation_body.dart';
import 'package:hywork/features/chat/widgets/conversation_header/conversation_header.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

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
    this.profiles,
    this.isCurrentAccount,
    this.currentUserId,
    this.onMarkedRead,
  });

  final ChatConversation conversation;
  final String? subtitle;
  final ValueChanged<ChatMessage?>? onLatestMessageChanged;
  final ApiChatsRepository? repository;
  final ChatMediaStore? mediaStore;
  final VoiceRecorder? voiceRecorder;
  final ChatAudioPlayer? audioPlayer;
  final DateTime Function()? recordingClock;
  final GalleryCubit Function()? galleryFactory;
  final Future<GalleryAttachment?> Function()? capturePhoto;
  final Widget? headerTitle;
  final PreferredSizeWidget? headerBottom;
  final bool allowBlocking;
  final ApiPublicProfileRepository? profiles;
  final bool Function()? isCurrentAccount;
  final String? Function()? currentUserId;
  final VoidCallback? onMarkedRead;

  @override
  Widget build(BuildContext context) {
    return ConversationBlocScope(
      conversationId: conversation.id,
      repository: repository,
      mediaStore: mediaStore,
      voiceRecorder: voiceRecorder,
      audioPlayer: audioPlayer,
      recordingClock: recordingClock,
      profiles: profiles,
      isCurrentAccount: isCurrentAccount,
      currentUserId: currentUserId,
      onMarkedRead: onMarkedRead,
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
  final _messageController = TextEditingController();
  final _messageFocusNode = FocusNode();
  final _scrollController = ScrollController();

  PageRoute<dynamic>? _route;
  ConversationCubit? _conversationRef;
  VoiceRecordingCubit? _recordingRef;
  VoicePlaybackCubit? _playbackRef;

  ConversationCubit get _conversation =>
      _conversationRef ?? context.read<ConversationCubit>();
  VoiceRecordingCubit get _recording =>
      _recordingRef ?? context.read<VoiceRecordingCubit>();
  VoicePlaybackCubit get _playback =>
      _playbackRef ?? context.read<VoicePlaybackCubit>();

  bool _routeVisible = true;
  bool _appForeground = true;
  bool _scrollToNewestAfterSend = false;
  final _activeConversation = ActiveConversationRegistration();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncLifecycle();
      _activeConversation.bind(_conversation);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _conversationRef = context.read<ConversationCubit>();
    _recordingRef = context.read<VoiceRecordingCubit>();
    _playbackRef = context.read<VoicePlaybackCubit>();
    final route = ModalRoute.of(context);
    if (route != _route) {
      entranceRouteObserver.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      if (_route != null) entranceRouteObserver.subscribe(this, _route!);
    }
  }

  @override
  void dispose() {
    _activeConversation.clear();
    WidgetsBinding.instance.removeObserver(this);
    entranceRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _messageController.removeListener(_onComposerChanged);
    final conversation = _conversationRef;
    if (conversation != null && !conversation.isClosed) {
      conversation.setComposerTyping(false);
    }
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onComposerChanged() {
    _conversation.setComposerTyping(_messageController.text.trim().isNotEmpty);
  }

  void _syncLifecycle() {
    _conversation.setLifecycle(
      visible: _routeVisible,
      foreground: _appForeground,
    );
  }

  void _pauseMedia({required bool cancelStarting}) {
    unawaited(_playback.pause());
    final phase = _recording.state.phase;
    if (phase == VoiceRecordingPhase.recording) {
      unawaited(_recording.stop());
    } else if (cancelStarting && phase == VoiceRecordingPhase.starting) {
      unawaited(_recording.cancel());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_conversation.loadOlder());
    }
  }

  bool get _nearLatestMessages {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 96;
  }

  String? _visibleTailId(ConversationState state) {
    if (state.visibleMessages.isEmpty) return null;
    return state.visibleMessages.last.id;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appForeground = true;
      _syncLifecycle();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      _appForeground = false;
      _syncLifecycle();
    }
    _pauseMedia(cancelStarting: state == AppLifecycleState.paused);
  }

  @override
  void didPushNext() {
    _routeVisible = false;
    _syncLifecycle();
    _pauseMedia(cancelStarting: false);
  }

  @override
  void didPopNext() {
    _routeVisible = true;
    _syncLifecycle();
  }

  @override
  void didPush() {
    _routeVisible = true;
    _syncLifecycle();
  }

  @override
  void didPop() {
    _routeVisible = false;
    _syncLifecycle();
  }

  double _toolbarHeight(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    return (scaler.scale(15) * 1.4 + scaler.scale(11) * 1.4 + 8)
        .clamp(70, double.infinity)
        .toDouble();
  }

  String? _headerSubtitle(ConversationState conversation) {
    if (conversation.peerTyping) {
      final english = Localizations.localeOf(context).languageCode == 'en';
      return ChatStrings.typingLabel(english: english);
    }
    return widget.subtitle;
  }

  void _scrollToNewest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  void _dismissComposerChrome() {
    if (_conversation.state.emojiVisible) _conversation.showEmoji(false);
  }

  Future<void> _sendText() async {
    final text = _messageController.text;
    _conversation.setComposerTyping(false);
    // Set before await so the message listener cannot miss a successful send.
    _scrollToNewestAfterSend = true;
    final sent = await _conversation.sendMessage(text);
    if (!mounted) return;
    if (!sent) {
      if (!_nearLatestMessages) _scrollToNewestAfterSend = false;
      return;
    }
    clearSentComposerDraft(_messageController, text);
  }

  Future<void> _toggleEmoji() async {
    if (_conversation.state.emojiVisible) {
      _conversation.showEmoji(false);
      _messageFocusNode.requestFocus();
      return;
    }
    _messageFocusNode.unfocus();
    await SystemChannels.textInput.invokeMethod<void>('TextInput.hide');
    if (mounted) _conversation.showEmoji(true);
  }

  Future<void> _startRecording() async {
    if (!_conversation.canSend) return;
    _messageFocusNode.unfocus();
    _dismissComposerChrome();
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
    _dismissComposerChrome();
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
    _dismissComposerChrome();
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
    _dismissComposerChrome();
    await _playback.pause();
    if (!mounted || !_conversation.canSend) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            CallScreen(conversation: widget.conversation, type: type),
      ),
    );
  }

  Future<void> _onMessageLongPress(String id) async {
    _messageFocusNode.unfocus();
    _dismissComposerChrome();
    final message = _conversation.state.messages
        .where((item) => item.id == id && !item.deleted)
        .firstOrNull;
    if (message == null) return;

    if (!message.isMine) {
      _conversation.startSelection(id);
      return;
    }

    final action = await showChatMessageDeleteSheet(context);
    if (!mounted || action == null) return;
    _conversation.startSelection(id);
    await _deleteSelected();
  }

  Future<void> _deleteSelected() async {
    final selected = _conversation.state.selected;
    final deletable = [
      for (final message in _conversation.state.messages)
        if (selected.contains(message.id) && message.isMine && !message.deleted)
          message,
    ];
    if (deletable.isEmpty) {
      _conversation.cancelSelection();
      return;
    }

    final confirmed = await confirmChatAction(
      context,
      title: deletable.length == 1
          ? AppStrings.deleteMyMessageQuestion
          : AppStrings.deleteMessageQuestion(deletable.length),
      description: ChatStrings.deleteMyMessageHelp,
      confirmLabel: AppStrings.delete,
    );
    if (!mounted || !confirmed) {
      _conversation.cancelSelection();
      return;
    }
    await _playback.pause();
    if (!mounted) return;
    await _conversation.deleteSelected();
    // Preview updates via the visible-tail BlocListener — no duplicate callback.
  }

  Future<void> _action(ConversationAction action) async {
    switch (action) {
      case ConversationAction.select:
        _messageFocusNode.unfocus();
        _dismissComposerChrome();
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
          await _conversation.setBlocked(true);
          _messageFocusNode.unfocus();
          _dismissComposerChrome();
          await _cancelRecording();
        } else {
          await _conversation.setBlocked(false);
        }
      case ConversationAction.copy:
        final messages = _conversation.state.messages.where(
          (message) =>
              _conversation.state.selected.contains(message.id) &&
              !message.deleted,
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

  ConversationHeader _header({
    required ConversationState conversation,
    required bool interactive,
    required bool recordingActive,
  }) {
    final selected = interactive
        ? conversation.messages.where(
            (message) => conversation.selected.contains(message.id),
          )
        : const <ChatMessage>[];

    return ConversationHeader(
      toolbarHeight: _toolbarHeight(context),
      conversation: widget.conversation,
      subtitle: _headerSubtitle(conversation),
      titleContent: widget.headerTitle,
      bottom: widget.headerBottom,
      allowBlocking: interactive && widget.allowBlocking,
      peerTyping: interactive && conversation.peerTyping,
      selectionMode: interactive && conversation.selectionMode,
      selectedCount: interactive ? conversation.selected.length : 0,
      blocked: interactive && conversation.blocked,
      hasMessages: interactive && conversation.visibleMessages.isNotEmpty,
      busy: !interactive
          ? conversation.loading
          : conversation.sendingMedia ||
                conversation.sending ||
                recordingActive ||
                conversation.pickingAttachment,
      canCopy:
          interactive &&
          selected.length == 1 &&
          !selected.single.deleted &&
          selected.single.text.isNotEmpty,
      onBack: interactive ? _back : () => Navigator.of(context).maybePop(),
      onDelete: interactive ? _deleteSelected : () {},
      onSelectAll: interactive ? _conversation.selectAll : () {},
      onAction: interactive ? _action : (_) {},
      onVoiceCall: interactive ? () => _openCall(CallType.voice) : () {},
      onVideoCall: interactive ? () => _openCall(CallType.video) : () {},
    );
  }

  Widget _bootstrapBody(ConversationState conversation) {
    if (conversation.loading && conversation.messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              conversation.error ?? ChatStrings.messagesLoadFailed,
              textAlign: TextAlign.center,
              textDirection: TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _conversation.load,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ConversationCubit, ConversationState>(
          listenWhen: (before, after) =>
              _visibleTailId(before) != _visibleTailId(after),
          listener: (context, state) {
            widget.onLatestMessageChanged?.call(_conversation.latestMessage);
            final shouldScroll =
                _scrollToNewestAfterSend || _nearLatestMessages;
            _scrollToNewestAfterSend = false;
            if (shouldScroll) _scrollToNewest();
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
        builder: (context, conversation) {
          final bootstrapping =
              conversation.loading && conversation.messages.isEmpty;
          final bootstrapError =
              conversation.error != null &&
              conversation.messages.isEmpty &&
              !conversation.loading;
          final interactive = !bootstrapping && !bootstrapError;

          return BlocBuilder<VoiceRecordingCubit, VoiceRecordingState>(
            buildWhen: (before, after) =>
                before.phase != after.phase || before.error != after.error,
            builder: (context, recording) {
              final recordingActive =
                  recording.phase != VoiceRecordingPhase.idle;
              final composerEnabled =
                  conversation.canSend &&
                  !conversation.blocked &&
                  !conversation.selectionMode &&
                  !conversation.pickingAttachment;

              return PopScope(
                canPop:
                    !interactive ||
                    (!conversation.emojiVisible &&
                        !conversation.selectionMode &&
                        !recordingActive),
                onPopInvokedWithResult: (didPop, result) {
                  if (!didPop &&
                      interactive &&
                      (conversation.emojiVisible ||
                          conversation.selectionMode ||
                          recordingActive)) {
                    _back();
                  }
                },
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Scaffold(
                    resizeToAvoidBottomInset: true,
                    appBar: _header(
                      conversation: conversation,
                      interactive: interactive,
                      recordingActive: recordingActive,
                    ),
                    body: interactive
                        ? ConversationBody(
                            conversation: conversation,
                            pickingAttachment: conversation.pickingAttachment,
                            recording: recording,
                            scrollController: _scrollController,
                            messageController: _messageController,
                            messageFocusNode: _messageFocusNode,
                            emojiVisible: conversation.emojiVisible,
                            composerEnabled: composerEnabled,
                            restrictionLabel: conversation.restrictionLabel,
                            onUnblock: () =>
                                unawaited(_conversation.setBlocked(false)),
                            onStartSelection: (id) =>
                                unawaited(_onMessageLongPress(id)),
                            onSelect: _conversation.toggleSelection,
                            onOpenAttachment: () =>
                                unawaited(_playback.pause()),
                            onCancelRecording: _cancelRecording,
                            onStopRecording: _recording.stop,
                            onSendVoice: _sendVoice,
                            onSend: () => unawaited(_sendText()),
                            onRecord: _startRecording,
                            onEmoji: _toggleEmoji,
                            onKeyboard: _dismissComposerChrome,
                            onFiles: _openAttachments,
                            onPhotos: () => _openGallery(GalleryTab.photo),
                          )
                        : _bootstrapBody(conversation),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
