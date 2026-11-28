import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/animations/screen_entrance/screen_entrance.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/features/calls/domain/call_session.dart';
import 'package:hywork/features/calls/presentation/pages/call_screen.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/data/device_voice_recorder.dart';
import 'package:hywork/features/chat/data/just_audio_chat_player.dart';
import 'package:hywork/features/chat/data/local_chat_media_store.dart';
import 'package:hywork/features/chat/domain/models/chat_conversation.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/domain/repositories/chat_messages_repository.dart';
import 'package:hywork/features/chat/domain/services/chat_audio_player.dart';
import 'package:hywork/features/chat/domain/services/chat_media_store.dart';
import 'package:hywork/features/chat/domain/services/voice_recorder.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/local_conversation_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/voice_playback_cubit.dart';
import 'package:hywork/features/chat/presentation/helpers/chat_attachment_flow.dart';
import 'package:hywork/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/chat_action_dialog.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/chat_message_delete_sheet.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/conversation_body.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/conversation_header.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/features/create_post/presentation/cubit/gallery_cubit.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

class ConversationScreen extends StatelessWidget {
  const ConversationScreen({
    super.key,
    required this.conversation,
    this.subtitle,
    this.onLatestMessageChanged,
    this.repository,
    this.localRepository,
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

  /// Production peer chat repository. Ignored when [localRepository] is set.
  final ApiChatsRepository? repository;

  /// Team/local chat path preserved for unrelated InMemory functionality.
  final ChatMessagesRepository? localRepository;
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
    final local = localRepository;
    final session = context.read<SessionCubit?>();
    final initial = session?.state;
    bool current() {
      if (isCurrentAccount != null) return isCurrentAccount!();
      if (session == null || initial == null) return false;
      return !session.isClosed &&
          session.state.status == SessionStatus.authenticated &&
          !session.state.isLoggingOut &&
          !session.state.logoutCleanupRequired &&
          session.state.userId != null &&
          session.state.userId == initial.userId &&
          session.state.accountRevision == initial.accountRevision;
    }

    String? userId() {
      if (currentUserId != null) return currentUserId!();
      return current() ? session?.state.userId : null;
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider<ConversationController>(
          create: (_) => local != null
              ? LocalConversationCubit(
                  conversationId: conversation.id,
                  repository: local,
                  mediaStore: mediaStore ?? LocalChatMediaStore(),
                )
              : ConversationCubit(
                  conversationId: conversation.id,
                  repository: repository ?? context.read<ApiChatsRepository>(),
                  mediaStore: mediaStore ?? LocalChatMediaStore(),
                  profiles:
                      profiles ?? context.read<ApiPublicProfileRepository?>(),
                  isCurrentAccount: current,
                  currentUserId: userId,
                  onMarkedRead: onMarkedRead,
                  realtime: context.read<RealtimeSocketClient?>(),
                ),
        ),
        BlocProvider(
          create: (_) => VoiceRecordingCubit(
            voiceRecorder ?? DeviceVoiceRecorder(),
            clock: recordingClock,
          ),
        ),
        BlocProvider(
          create: (_) =>
              VoicePlaybackCubit(audioPlayer ?? JustAudioChatPlayer()),
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
  ConversationController get _conversation =>
      context.read<ConversationController>();
  VoiceRecordingCubit get _recording => context.read<VoiceRecordingCubit>();
  VoicePlaybackCubit get _playback => context.read<VoicePlaybackCubit>();

  bool _routeVisible = true;
  bool _appForeground = true;
  bool _scrollToNewestAfterSend = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onComposerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _syncLifecycle();
      _bindActiveConversation();
    });
  }

  void _onComposerChanged() {
    final typing = _messageController.text.trim().isNotEmpty;
    _conversation.setComposerTyping(typing);
  }

  String? _headerSubtitle(ConversationState conversation) {
    if (conversation.peerTyping) {
      final english = Localizations.localeOf(context).languageCode == 'en';
      return ChatStrings.typingLabel(english: english);
    }
    return widget.subtitle;
  }

  void _bindActiveConversation() {
    final conversation = _conversation;
    if (conversation is! ConversationCubit) return;
    final id = conversation.conversationId;
    PushNotifications.activeConversationId = id;
    // Coalesce with silent sync so FCM + Socket.IO do not wipe/reload the list.
    PushNotifications.refreshActiveConversation = () {
      if (PushNotifications.activeConversationId != id) {
        return Future.value();
      }
      return conversation.reconcileSilently();
    };
  }

  void _clearActiveConversation() {
    if (PushNotifications.activeConversationId != widget.conversation.id) {
      return;
    }
    PushNotifications.activeConversationId = null;
    PushNotifications.refreshActiveConversation = null;
  }

  void _syncLifecycle() {
    _conversation.setLifecycle(
      visible: _routeVisible,
      foreground: _appForeground,
    );
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // reverse:true — maxScrollExtent is the older end.
    if (position.pixels >= position.maxScrollExtent - 240) {
      unawaited(_conversation.loadOlder());
    }
  }

  bool get _nearLatestMessages {
    if (!_scrollController.hasClients) return true;
    return _scrollController.offset <= 96;
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
    // BlocProvider disposes ConversationCubit, which stops polling timers.
    _clearActiveConversation();
    WidgetsBinding.instance.removeObserver(this);
    entranceRouteObserver.unsubscribe(this);
    _scrollController.removeListener(_onScroll);
    _messageController.removeListener(_onComposerChanged);
    _conversation.setComposerTyping(false);
    _messageController.dispose();
    _messageFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
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
    _routeVisible = false;
    _syncLifecycle();
    unawaited(_playback.pause());
    if (_recording.state.phase == VoiceRecordingPhase.recording) {
      unawaited(_recording.stop());
    }
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

  void _scrollToNewest() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted && _scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    }
  });

  Future<void> _sendText() async {
    final text = _messageController.text;
    _conversation.setComposerTyping(false);
    final sent = await _conversation.sendMessage(text);
    if (sent && mounted) {
      _scrollToNewestAfterSend = true;
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

  Future<void> _onMessageLongPress(String id) async {
    _messageFocusNode.unfocus();
    _keyboard();
    final message = _conversation.state.messages
        .where((item) => item.id == id && !item.deleted)
        .firstOrNull;
    if (message == null) return;

    // Swagger only documents deleting own messages (soft-delete for the chat).
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
    final deletable = [
      for (final message in _conversation.state.messages)
        if (_conversation.state.selected.contains(message.id) &&
            message.isMine &&
            !message.deleted)
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
    if (!mounted) return;
    if (_conversation.state.error != null) {
      AppToast.error(context, _conversation.state.error!);
      return;
    }
    widget.onLatestMessageChanged?.call(_conversation.latestMessage);
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
          await _conversation.setBlocked(true);
          _messageFocusNode.unfocus();
          _keyboard();
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

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ConversationController, ConversationState>(
        listenWhen: (before, after) {
          final beforeLast = before.visibleMessages.isEmpty
              ? null
              : before.visibleMessages.last.id;
          final afterLast = after.visibleMessages.isEmpty
              ? null
              : after.visibleMessages.last.id;
          return beforeLast != afterLast || before.blocked != after.blocked;
        },
        listener: (context, state) {
          widget.onLatestMessageChanged?.call(_conversation.latestMessage);
          final shouldScroll = _scrollToNewestAfterSend || _nearLatestMessages;
          _scrollToNewestAfterSend = false;
          if (shouldScroll) _scrollToNewest();
        },
      ),
      BlocListener<ConversationController, ConversationState>(
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
    child: BlocBuilder<ConversationController, ConversationState>(
      builder: (context, conversation) {
        if (conversation.loading && conversation.messages.isEmpty) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              appBar: ConversationHeader(
                toolbarHeight:
                    (MediaQuery.textScalerOf(context).scale(15) * 1.4 +
                            MediaQuery.textScalerOf(context).scale(11) * 1.4 +
                            8)
                        .clamp(70, double.infinity),
                conversation: widget.conversation,
                subtitle: _headerSubtitle(conversation),
                titleContent: widget.headerTitle,
                bottom: widget.headerBottom,
                allowBlocking: false,
                selectionMode: false,
                selectedCount: 0,
                blocked: false,
                hasMessages: false,
                busy: true,
                canCopy: false,
                onBack: () => Navigator.of(context).maybePop(),
                onDelete: () {},
                onSelectAll: () {},
                onAction: (_) {},
                onVoiceCall: () {},
                onVideoCall: () {},
              ),
              body: const Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (conversation.error != null &&
            conversation.messages.isEmpty &&
            !conversation.loading) {
          return Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              appBar: ConversationHeader(
                toolbarHeight:
                    (MediaQuery.textScalerOf(context).scale(15) * 1.4 +
                            MediaQuery.textScalerOf(context).scale(11) * 1.4 +
                            8)
                        .clamp(70, double.infinity),
                conversation: widget.conversation,
                subtitle: _headerSubtitle(conversation),
                titleContent: widget.headerTitle,
                bottom: widget.headerBottom,
                allowBlocking: false,
                selectionMode: false,
                selectedCount: 0,
                blocked: false,
                hasMessages: false,
                busy: false,
                canCopy: false,
                onBack: () => Navigator.of(context).maybePop(),
                onDelete: () {},
                onSelectAll: () {},
                onAction: (_) {},
                onVoiceCall: () {},
                onVideoCall: () {},
              ),
              body: Center(
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
              ),
            ),
          );
        }

        return BlocBuilder<VoiceRecordingCubit, VoiceRecordingState>(
          builder: (context, recording) {
            final selected = conversation.messages.where(
              (message) => conversation.selected.contains(message.id),
            );
            final recordingActive = recording.phase != VoiceRecordingPhase.idle;
            final composerEnabled =
                conversation.canSend &&
                !conversation.blocked &&
                !conversation.selectionMode &&
                !_conversation.state.pickingAttachment;
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
                    subtitle: _headerSubtitle(conversation),
                    titleContent: widget.headerTitle,
                    bottom: widget.headerBottom,
                    allowBlocking: widget.allowBlocking,
                    peerTyping: conversation.peerTyping,
                    selectionMode: conversation.selectionMode,
                    selectedCount: conversation.selected.length,
                    blocked: conversation.blocked,
                    hasMessages: conversation.visibleMessages.isNotEmpty,
                    busy:
                        conversation.sendingMedia ||
                        conversation.sending ||
                        recordingActive ||
                        _conversation.state.pickingAttachment,
                    canCopy:
                        selected.length == 1 &&
                        !selected.single.deleted &&
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
                    composerEnabled: composerEnabled,
                    restrictionLabel: conversation.restrictionLabel,
                    onUnblock: () => unawaited(_conversation.setBlocked(false)),
                    onStartSelection: (id) =>
                        unawaited(_onMessageLongPress(id)),
                    onSelect: _conversation.toggleSelection,
                    onOpenAttachment: () => unawaited(_playback.pause()),
                    onCancelRecording: _cancelRecording,
                    onStopRecording: _recording.stop,
                    onSendVoice: _sendVoice,
                    onSend: () => unawaited(_sendText()),
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
        );
      },
    ),
  );
}
