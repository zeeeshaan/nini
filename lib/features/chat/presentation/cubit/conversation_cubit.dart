import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/core/network/realtime/realtime_connection_state.dart';
import 'package:hywork/core/network/realtime/realtime_events.dart';
import 'package:hywork/core/network/realtime/realtime_socket_client.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/domain/backend_chat_mapper.dart';
import 'package:hywork/features/chat/domain/chat_sync.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/domain/services/chat_media_store.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';

class ConversationState {
  const ConversationState({
    this.messages = const [],
    this.loading = false,
    this.loadingMore = false,
    this.refreshing = false,
    this.blocked = false,
    this.canSend = true,
    this.cannotSendReason,
    this.peerUserId,
    this.warnings = const [],
    this.hasMore = false,
    this.nextBefore,
    this.sending = false,
    this.sendingMedia = false,
    this.selectionMode = false,
    this.emojiVisible = false,
    this.pickingAttachment = false,
    this.selected = const {},
    this.error,
    this.markedRead = false,
    this.peerTyping = false,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool loadingMore;
  final bool refreshing;
  final bool blocked;
  final bool canSend;
  final String? cannotSendReason;
  final String? peerUserId;
  final List<BackendChatWarning> warnings;
  final bool hasMore;
  final String? nextBefore;
  final bool sending;
  final bool sendingMedia;
  final bool selectionMode;
  final bool emojiVisible;
  final bool pickingAttachment;
  final Set<String> selected;
  final String? error;
  final bool markedRead;
  final bool peerTyping;

  /// Messages shown in the bubble list — soft-deleted rows stay in [messages]
  /// for tombstone / pagination sync but are never rendered.
  List<ChatMessage> get visibleMessages => [
    for (final message in messages)
      if (!message.deleted) message,
  ];

  String? get restrictionLabel =>
      canSend ? null : ChatStrings.cannotSendReason(cannotSendReason);

  ConversationState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? loadingMore,
    bool? refreshing,
    bool? blocked,
    bool? canSend,
    String? cannotSendReason,
    bool clearCannotSendReason = false,
    String? peerUserId,
    List<BackendChatWarning>? warnings,
    bool? hasMore,
    String? nextBefore,
    bool clearNextBefore = false,
    bool? sending,
    bool? sendingMedia,
    bool? selectionMode,
    bool? emojiVisible,
    bool? pickingAttachment,
    Set<String>? selected,
    String? error,
    bool clearError = false,
    bool? markedRead,
    bool? peerTyping,
  }) => ConversationState(
    messages: messages ?? this.messages,
    loading: loading ?? this.loading,
    loadingMore: loadingMore ?? this.loadingMore,
    refreshing: refreshing ?? this.refreshing,
    blocked: blocked ?? this.blocked,
    canSend: canSend ?? this.canSend,
    cannotSendReason: clearCannotSendReason
        ? null
        : (cannotSendReason ?? this.cannotSendReason),
    peerUserId: peerUserId ?? this.peerUserId,
    warnings: warnings ?? this.warnings,
    hasMore: hasMore ?? this.hasMore,
    nextBefore: clearNextBefore ? null : (nextBefore ?? this.nextBefore),
    sending: sending ?? this.sending,
    sendingMedia: sendingMedia ?? this.sendingMedia,
    selectionMode: selectionMode ?? this.selectionMode,
    emojiVisible: emojiVisible ?? this.emojiVisible,
    pickingAttachment: pickingAttachment ?? this.pickingAttachment,
    selected: selected ?? this.selected,
    error: clearError ? null : (error ?? this.error),
    markedRead: markedRead ?? this.markedRead,
    peerTyping: peerTyping ?? this.peerTyping,
  );
}

/// Shared conversation actions for API and local (team) chat screens.
abstract class ConversationController extends Cubit<ConversationState> {
  ConversationController(super.initialState);

  bool get canSend;
  ChatMessage? get latestMessage;

  void showEmoji(bool visible);
  void pickingAttachment(bool busy);
  Future<bool> sendMessage(String text);
  ChatMessage? sendLocation(ChatLocation location);
  Future<List<ChatMessage>> sendAttachments(List<GalleryAttachment> selected);
  Future<ChatMessage?> sendVoice(String path, Duration duration);
  void startSelection([String? id]);
  void toggleSelection(String id);
  void selectAll();
  void cancelSelection();
  Future<void> deleteSelected();
  Future<void> clearMessages();
  Future<void> setBlocked(bool blocked);
  Future<void> load();
  Future<void> loadOlder();

  /// Route + app foreground visibility for Phase 3 REST polling.
  void setLifecycle({required bool visible, required bool foreground}) {}

  /// Outgoing typing signal (throttled by [RealtimeSocketClient]).
  void setComposerTyping(bool typing) {}

  /// Coalesced REST reconcile (FCM / reconnect) without loading indicators.
  Future<void> reconcileSilently({bool refreshDetails = true}) async {}
}

/// Conversation screen cubit backed by Chat REST with lifecycle polling +
/// Phase C Socket.IO live updates (shared [RealtimeSocketClient]).
class ConversationCubit extends ConversationController {
  ConversationCubit({
    required this.conversationId,
    required this.repository,
    required this.isCurrentAccount,
    required this.currentUserId,
    this.mediaStore,
    this.profiles,
    this.onMarkedRead,
    this.realtime,
    this.pollInterval = ChatSync.messagePollInterval,
    this.detailsInterval = ChatSync.detailsPollInterval,
    this.peerTypingTimeout = ChatSync.peerTypingTimeout,
  }) : super(const ConversationState(loading: true)) {
    _bindRealtime();
    if (isCurrentAccount()) {
      unawaited(load());
    } else {
      emit(const ConversationState());
    }
  }

  final String conversationId;
  final ApiChatsRepository repository;
  final bool Function() isCurrentAccount;
  final String? Function() currentUserId;
  final ChatMediaStore? mediaStore;
  final ApiPublicProfileRepository? profiles;
  final void Function()? onMarkedRead;
  final RealtimeSocketClient? realtime;

  /// Overridable for deterministic tests (production uses [ChatSync]).
  final Duration pollInterval;
  final Duration detailsInterval;
  final Duration peerTypingTimeout;

  static const _pageSize = 30;

  int _loadRevision = 0;
  int _sendVersion = 0;
  int _pollGeneration = 0;
  int _pollFailures = 0;
  Future<void>? _loadMoreInFlight;
  Future<bool>? _silentInFlight;
  int? _silentInFlightGeneration;
  Timer? _pollTimer;
  Timer? _detailsTimer;
  Timer? _peerTypingTimer;
  Timer? _typingHeartbeat;
  StreamSubscription<RealtimeEvent>? _realtimeEvents;
  StreamSubscription<RealtimeConnectionState>? _realtimeStates;
  bool _markingRead = false;
  bool _initialReady = false;
  bool _routeVisible = false;
  bool _appForeground = true;
  bool _socketReady = false;
  bool _socketReconciled = false;
  bool _composerTyping = false;
  DateTime? _lastDetailsAt;
  DateTime? _peerReadAt;

  /// Soft-delete tombstones for this open conversation (cleared on cubit close).
  /// Not hard-capped: FIFO eviction can let REST restore deleted content.
  final Set<String> _locallyDeleted = {};

  /// When gap fill hits [ChatSync.maxGapPages] without overlap, resume from this
  /// `before` cursor on the next sync so the same tip pages are not re-fetched.
  String? _gapResumeBefore;

  bool get _isActive =>
      !isClosed &&
      _initialReady &&
      _routeVisible &&
      _appForeground &&
      isCurrentAccount();

  /// Continuous 4s message polling until socket is ready *and* REST-reconciled.
  bool get _shouldMessagePoll =>
      _isActive && !(_socketReady && _socketReconciled);

  /// 24s details refresh stays on while the conversation is visible.
  bool get _shouldDetailsPoll => _isActive;

  @visibleForTesting
  bool get isPollingScheduled => _pollTimer != null;

  @visibleForTesting
  bool get isDetailsPollingScheduled => _detailsTimer != null;

  @visibleForTesting
  bool get isSocketReadyForPolling => _socketReady;

  @visibleForTesting
  Future<bool> debugPollOnce({bool refreshDetails = false}) =>
      _silentSync(_pollGeneration, refreshDetails: refreshDetails);

  void _bindRealtime() {
    final client = realtime;
    if (client == null) return;
    _socketReady = client.isReady;
    _realtimeStates = client.connectionStates.listen(_onRealtimeState);
    _realtimeEvents = client.events.listen(_onRealtimeEvent);
  }

  void _onRealtimeState(RealtimeConnectionState next) {
    if (isClosed || !isCurrentAccount()) return;
    final ready = next == RealtimeConnectionState.ready;
    if (ready == _socketReady) {
      _syncSyncTimers();
      return;
    }
    _socketReady = ready;
    if (!ready) {
      _socketReconciled = false;
      _clearPeerTyping();
      _syncSyncTimers();
      return;
    }
    unawaited(_onSocketBecameReady());
  }

  Future<void> _onSocketBecameReady() async {
    if (isClosed || !isCurrentAccount()) return;
    if (!_initialReady) {
      _syncSyncTimers();
      return;
    }
    final generation = ++_pollGeneration;
    // Drop orphaned poll timers tied to the previous generation.
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopDetailsTimer();
    final ok = await _silentSync(generation, refreshDetails: true);
    if (isClosed || generation != _pollGeneration || !isCurrentAccount()) {
      return;
    }
    // Only pause message polling after a successful REST reconcile.
    _socketReconciled = ok && _socketReady;
    if (_socketReconciled && _routeVisible && _appForeground) {
      await _markReadNow();
    }
    // Replay composer typing once the socket is ready (earlier emits were dropped).
    _flushComposerTyping(force: true);
    if (isClosed || generation != _pollGeneration) return;
    _syncSyncTimers();
  }

  void _onRealtimeEvent(RealtimeEvent event) {
    if (isClosed || !isCurrentAccount()) return;
    switch (event) {
      case RealtimeRecovered():
        unawaited(_recoverAfterReconnect());
      case RealtimeChatMessage(:final conversationId, :final message):
        if (conversationId != this.conversationId) return;
        _applySocketMessage(message);
      case RealtimeChatRead(
        :final conversationId,
        :final readBy,
        :final readAt,
      ):
        if (conversationId != this.conversationId) return;
        _applySocketRead(readBy: readBy, readAt: readAt);
      case RealtimeChatTyping(
        :final conversationId,
        :final userId,
        :final typing,
      ):
        if (conversationId != this.conversationId) return;
        _applySocketTyping(userId: userId, typing: typing);
      case RealtimeChatMessageDeleted(:final conversationId, :final messageId):
        if (conversationId != this.conversationId) return;
        _applySocketDeleted(messageId);
      default:
        break;
    }
  }

  Future<void> _recoverAfterReconnect() async {
    if (isClosed || !isCurrentAccount()) return;
    _socketReady = realtime?.isReady == true;
    _socketReconciled = false;
    if (!_initialReady) {
      _syncSyncTimers();
      return;
    }
    final generation = ++_pollGeneration;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopDetailsTimer();
    // Keep message polling until recovery REST completes successfully.
    _syncSyncTimers();
    final ok = await _silentSync(generation, refreshDetails: true);
    if (isClosed || generation != _pollGeneration || !isCurrentAccount()) {
      return;
    }
    _socketReconciled = ok && _socketReady;
    if (_socketReconciled && _routeVisible && _appForeground) {
      await _markReadNow();
    }
    _flushComposerTyping(force: true);
    if (isClosed || generation != _pollGeneration) return;
    _syncSyncTimers();
  }

  void _applySocketMessage(BackendChatMessage backend) {
    if (isClosed || !isCurrentAccount()) return;
    final mapped = chatMessageFromBackend(backend);
    final before = state.messages;
    final merged = _mergeMessages(existing: before, incoming: [mapped]);
    if (!_sameMessages(before, merged)) {
      emit(
        state.copyWith(
          messages: merged,
          loading: false,
          refreshing: false,
          clearError: true,
        ),
      );
    }
    final isNewIncoming =
        !mapped.isMine &&
        !mapped.deleted &&
        !before.any((prior) => prior.id == mapped.id);
    if (isNewIncoming && _routeVisible && _appForeground) {
      unawaited(_markReadNow());
    }
  }

  void _applySocketRead({required String readBy, required DateTime readAt}) {
    if (isClosed || !isCurrentAccount()) return;
    final me = currentUserId();
    if (me != null && readBy == me) {
      // Own mark-read — ticks are for the peer reading our messages.
      return;
    }
    final readAtUtc = readAt.toUtc();
    if (_peerReadAt != null && readAtUtc.isBefore(_peerReadAt!.toUtc())) {
      return;
    }
    _peerReadAt = readAtUtc;
    final before = state.messages;
    final updated = [
      for (final message in before)
        if (message.isMine &&
            !message.deleted &&
            !message.sentAt.toUtc().isAfter(readAtUtc) &&
            message.deliveryStatus != ChatDeliveryStatus.read)
          message.copyWith(deliveryStatus: ChatDeliveryStatus.read)
        else
          message,
    ];
    if (!_sameMessages(before, updated)) {
      emit(state.copyWith(messages: List.unmodifiable(updated)));
    }
  }

  void _applySocketTyping({required String userId, required bool typing}) {
    if (isClosed || !isCurrentAccount()) return;
    final me = currentUserId();
    if (me != null && userId == me) return;
    _peerTypingTimer?.cancel();
    _peerTypingTimer = null;
    if (!typing) {
      _clearPeerTyping();
      return;
    }
    if (!state.peerTyping) {
      emit(state.copyWith(peerTyping: true));
    }
    _peerTypingTimer = Timer(peerTypingTimeout, _clearPeerTyping);
  }

  void _clearPeerTyping() {
    _peerTypingTimer?.cancel();
    _peerTypingTimer = null;
    if (!isClosed && state.peerTyping) {
      emit(state.copyWith(peerTyping: false));
    }
  }

  void _rememberLocalDelete(String messageId) {
    _locallyDeleted.add(messageId);
  }

  void _applySocketDeleted(String messageId) {
    if (isClosed || !isCurrentAccount()) return;
    _rememberLocalDelete(messageId);
    final before = state.messages;
    final known = before.any((message) => message.id == messageId);
    if (!known) {
      // Tombstone id so a later REST page cannot restore content.
      return;
    }
    final updated = [
      for (final message in before)
        message.id == messageId
            ? _applyLocalDelete(message.copyWith(deleted: true))
            : message,
    ];
    if (!_sameMessages(before, updated)) {
      emit(state.copyWith(messages: List.unmodifiable(updated)));
    }
  }

  void _syncSyncTimers() {
    if (!_isActive) {
      _stopPolling(invalidateInFlight: true);
      _stopDetailsTimer();
      return;
    }
    // Pause 4s message polling only after socket is ready *and* reconciled.
    final live = _socketReady && _socketReconciled;
    if (live) {
      _stopPolling();
      _maybeStartDetailsTimer();
    } else {
      _stopDetailsTimer();
      _maybeStartPolling();
    }
  }

  @override
  bool get canSend =>
      !isClosed &&
      state.canSend &&
      !state.blocked &&
      !state.sending &&
      !state.sendingMedia &&
      isCurrentAccount();

  @override
  ChatMessage? get latestMessage {
    for (var i = state.messages.length - 1; i >= 0; i--) {
      if (!state.messages[i].deleted) return state.messages[i];
    }
    return null;
  }

  @override
  void showEmoji(bool visible) {
    if (isClosed) return;
    emit(state.copyWith(emojiVisible: visible, error: state.error));
  }

  @override
  void pickingAttachment(bool busy) {
    if (isClosed) return;
    emit(state.copyWith(pickingAttachment: busy, error: state.error));
  }

  @override
  Future<void> load() => _open(replace: true, keepExisting: false);

  Future<void> refresh() => _open(replace: true, keepExisting: true);

  @override
  void setLifecycle({required bool visible, required bool foreground}) {
    final wasActive = _isActive;
    _routeVisible = visible;
    _appForeground = foreground;
    if (!_routeVisible) {
      setComposerTyping(false);
      _clearPeerTyping();
    }
    if (!_isActive) {
      _stopPolling(invalidateInFlight: true);
      _stopDetailsTimer();
      return;
    }
    if (!wasActive) {
      unawaited(_resumeActive());
    } else {
      _syncSyncTimers();
    }
  }

  @override
  void setComposerTyping(bool typing) {
    if (!isCurrentAccount()) return;
    _composerTyping = typing;
    if (!typing) {
      _typingHeartbeat?.cancel();
      _typingHeartbeat = null;
      realtime?.sendTyping(conversationId: conversationId, typing: false);
      return;
    }
    _flushComposerTyping();
    // Spec: peer hides typing after ~5s without a new event — heartbeat ≤2s.
    _typingHeartbeat ??= Timer.periodic(const Duration(seconds: 2), (_) {
      if (isClosed || !_composerTyping || !isCurrentAccount()) {
        _typingHeartbeat?.cancel();
        _typingHeartbeat = null;
        return;
      }
      _flushComposerTyping();
    });
  }

  void _flushComposerTyping({bool force = false}) {
    if (!_composerTyping || !isCurrentAccount()) return;
    realtime?.sendTyping(
      conversationId: conversationId,
      typing: true,
      force: force,
    );
  }

  @override
  Future<void> reconcileSilently({bool refreshDetails = true}) async {
    if (isClosed || !_initialReady || !isCurrentAccount()) return;
    await _silentSync(_pollGeneration, refreshDetails: refreshDetails);
  }

  @override
  Future<void> close() async {
    _stopPolling(invalidateInFlight: true);
    _stopDetailsTimer();
    _peerTypingTimer?.cancel();
    _peerTypingTimer = null;
    _typingHeartbeat?.cancel();
    _typingHeartbeat = null;
    _composerTyping = false;
    await _realtimeEvents?.cancel();
    await _realtimeStates?.cancel();
    _realtimeEvents = null;
    _realtimeStates = null;
    if (_socketReady) {
      realtime?.sendTyping(conversationId: conversationId, typing: false);
    }
    return super.close();
  }

  void _stopPolling({bool invalidateInFlight = false}) {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (invalidateInFlight) _pollGeneration++;
  }

  void _stopDetailsTimer() {
    _detailsTimer?.cancel();
    _detailsTimer = null;
  }

  Future<void> _resumeActive() async {
    if (!_routeVisible || !_appForeground || !isCurrentAccount() || isClosed) {
      return;
    }
    final generation = ++_pollGeneration;
    _pollTimer?.cancel();
    _pollTimer = null;
    _stopDetailsTimer();
    if (!_initialReady) return;
    await _silentSync(generation, refreshDetails: true);
    if (isClosed || generation != _pollGeneration) return;
    await _markReadNow();
    if (isClosed || generation != _pollGeneration || !_isActive) return;
    if (_socketReady) {
      _socketReconciled = true;
    }
    _syncSyncTimers();
  }

  void _maybeStartPolling() {
    if (!_shouldMessagePoll) {
      _stopPolling();
      return;
    }
    if (_pollTimer != null || _silentInFlight != null) return;
    _scheduleNextPoll(_pollGeneration);
  }

  void _maybeStartDetailsTimer() {
    if (!_shouldDetailsPoll || !_socketReady || !_socketReconciled) {
      _stopDetailsTimer();
      return;
    }
    if (_detailsTimer != null) return;
    _scheduleNextDetails(_pollGeneration);
  }

  Duration _backoffDelay() {
    if (_pollFailures <= 0) return pollInterval;
    final shift = math.min(_pollFailures, 4);
    return pollInterval * (1 << (shift - 1));
  }

  void _scheduleNextPoll(int generation) {
    _pollTimer?.cancel();
    if (isClosed || generation != _pollGeneration || !_shouldMessagePoll) {
      _pollTimer = null;
      return;
    }
    _pollTimer = Timer(_backoffDelay(), () {
      if (isClosed || generation != _pollGeneration) return;
      unawaited(_onPollTick(generation));
    });
  }

  void _scheduleNextDetails(int generation) {
    _detailsTimer?.cancel();
    if (isClosed ||
        generation != _pollGeneration ||
        !_shouldDetailsPoll ||
        !_socketReady ||
        !_socketReconciled) {
      _detailsTimer = null;
      return;
    }
    final elapsed = _lastDetailsAt == null
        ? detailsInterval
        : detailsInterval - DateTime.now().difference(_lastDetailsAt!);
    final delay = elapsed.isNegative ? Duration.zero : elapsed;
    _detailsTimer = Timer(delay, () {
      if (isClosed || generation != _pollGeneration) return;
      unawaited(_onDetailsTick(generation));
    });
  }

  Future<void> _onPollTick(int generation) async {
    if (isClosed || generation != _pollGeneration || !_shouldMessagePoll) {
      return;
    }
    await _silentSync(generation);
    if (isClosed || generation != _pollGeneration) return;
    _scheduleNextPoll(generation);
  }

  Future<void> _onDetailsTick(int generation) async {
    if (isClosed ||
        generation != _pollGeneration ||
        !_shouldDetailsPoll ||
        !_socketReady ||
        !_socketReconciled) {
      return;
    }
    try {
      await _refreshPermissions(silent: true);
      _lastDetailsAt = DateTime.now();
    } catch (_) {}
    if (isClosed || generation != _pollGeneration) return;
    _scheduleNextDetails(generation);
  }

  /// Returns `true` when the silent REST pass finished without error.
  Future<bool> _silentSync(int generation, {bool refreshDetails = false}) {
    // Only coalesce within the same poll generation — a newer reconcile must
    // not inherit a superseded in-flight result.
    if (_silentInFlight != null && _silentInFlightGeneration == generation) {
      return _silentInFlight!;
    }
    late final Future<bool> future;
    future = _runSilentSync(generation, refreshDetails: refreshDetails)
        .whenComplete(() {
          if (identical(_silentInFlight, future)) {
            _silentInFlight = null;
            _silentInFlightGeneration = null;
          }
        });
    _silentInFlight = future;
    _silentInFlightGeneration = generation;
    return future;
  }

  Future<bool> _runSilentSync(
    int generation, {
    required bool refreshDetails,
  }) async {
    if (isClosed ||
        generation != _pollGeneration ||
        !_initialReady ||
        !isCurrentAccount()) {
      return false;
    }

    final before = state.messages;
    try {
      final dueDetails =
          refreshDetails ||
          _lastDetailsAt == null ||
          DateTime.now().difference(_lastDetailsAt!) >= detailsInterval;
      if (dueDetails) {
        await _refreshPermissions(silent: true);
        _lastDetailsAt = DateTime.now();
        if (isClosed || generation != _pollGeneration || !isCurrentAccount()) {
          return false;
        }
      }

      final fill = await _fetchLatestWithGapFill(before);
      if (isClosed || generation != _pollGeneration || !isCurrentAccount()) {
        return false;
      }

      final merged = _mergeMessages(
        existing: state.messages,
        incoming: fill.messages,
      );
      if (!_sameMessages(before, merged)) {
        // Preserve older-page cursor (hasMore / nextBefore) during latest polls.
        emit(
          state.copyWith(
            messages: merged,
            loading: false,
            refreshing: false,
            clearError: true,
          ),
        );
      }

      final hadNewIncoming = merged.any(
        (message) =>
            !message.isMine &&
            !message.deleted &&
            !before.any((prior) => prior.id == message.id),
      );
      if (hadNewIncoming && _routeVisible && _appForeground) {
        await _markReadNow();
      }

      _pollFailures = 0;
      // Incomplete gap fill must keep fallback polling / retry reconcile.
      return fill.complete;
    } on DioException catch (error) {
      if (isClosed || generation != _pollGeneration) return false;
      _pollFailures++;
      final status = error.response?.statusCode;
      if (status == 401) return false;
      if (status == 403 || status == 409 || status == 422) {
        await _refreshPermissions(silent: true);
      }
      // Silent: keep conversation visible; no snackbar / loading wipe.
      return false;
    } catch (_) {
      if (isClosed || generation != _pollGeneration) return false;
      _pollFailures++;
      return false;
    }
  }

  /// Fetches latest messages and walks older pages until history overlaps.
  ///
  /// [complete] is false when the gap still exceeds [ChatSync.maxGapPages] —
  /// callers must not treat that as a finished live reconcile. The next call
  /// resumes from [_gapResumeBefore] so progress continues without re-walking
  /// the same tip pages indefinitely.
  Future<({List<ChatMessage> messages, bool complete})> _fetchLatestWithGapFill(
    List<ChatMessage> existing,
  ) async {
    final knownIds = {for (final message in existing) message.id};
    final page = await repository.listMessages(
      conversationId,
      limit: _pageSize,
    );
    final collected = <BackendChatMessage>[...page.items];
    var overlaps = page.items.any((item) => knownIds.contains(item.id));
    var cursor = page.nextBefore;
    var hasMore = page.hasMore;
    var pages = 0;

    final resume = _gapResumeBefore;
    if (resume != null && ProfileCategory.isBackendId(resume)) {
      // Continue the unfinished walk instead of restarting at the tip.
      cursor = resume;
      hasMore = true;
      overlaps = false;
    }

    while (!overlaps &&
        knownIds.isNotEmpty &&
        hasMore &&
        cursor != null &&
        pages < ChatSync.maxGapPages) {
      pages++;
      final older = await repository.listMessages(
        conversationId,
        before: cursor,
        limit: _pageSize,
      );
      collected.addAll(older.items);
      overlaps = older.items.any((item) => knownIds.contains(item.id));
      cursor = older.nextBefore;
      hasMore = older.hasMore;
    }

    final hitPageCapWithoutOverlap =
        knownIds.isNotEmpty &&
        !overlaps &&
        hasMore &&
        cursor != null &&
        pages >= ChatSync.maxGapPages;

    _gapResumeBefore = hitPageCapWithoutOverlap ? cursor : null;

    return (
      messages: chronologicalMessagesFromBackend(collected),
      complete: !hitPageCapWithoutOverlap,
    );
  }

  bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].deleted != b[i].deleted ||
          a[i].text != b[i].text ||
          a[i].imageUrl != b[i].imageUrl ||
          a[i].deliveryStatus != b[i].deliveryStatus) {
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> loadOlder() {
    if (state.loading ||
        state.refreshing ||
        state.loadingMore ||
        !state.hasMore ||
        state.nextBefore == null ||
        !isCurrentAccount()) {
      return Future.value();
    }
    return _loadMoreInFlight ??= _loadOlderMessages().whenComplete(
      () => _loadMoreInFlight = null,
    );
  }

  Future<void> _open({
    required bool replace,
    required bool keepExisting,
  }) async {
    if (isClosed) return;
    if (!isCurrentAccount()) {
      emit(const ConversationState());
      return;
    }
    final revision = ++_loadRevision;
    emit(
      state.copyWith(
        loading: replace && !keepExisting,
        refreshing: replace && keepExisting,
        clearError: true,
        messages: replace && !keepExisting ? const [] : null,
        hasMore: replace && !keepExisting ? false : null,
        clearNextBefore: replace && !keepExisting,
      ),
    );

    try {
      final detail = await repository.getChat(conversationId);
      if (isClosed || revision != _loadRevision || !isCurrentAccount()) return;

      final page = await repository.listMessages(
        conversationId,
        limit: _pageSize,
      );
      if (isClosed || revision != _loadRevision || !isCurrentAccount()) return;

      final messages = _mergeMessages(
        existing: replace ? const [] : state.messages,
        incoming: chronologicalMessagesFromBackend(page.items),
      );

      emit(
        state.copyWith(
          messages: messages,
          loading: false,
          refreshing: false,
          blocked: detail.iBlocked,
          canSend: detail.canSend,
          cannotSendReason: detail.cannotSendReason,
          clearCannotSendReason: detail.cannotSendReason == null,
          peerUserId: detail.user.id,
          warnings: detail.warnings,
          hasMore: page.hasMore,
          nextBefore: page.nextBefore,
          clearNextBefore: page.nextBefore == null,
          clearError: true,
        ),
      );
      _initialReady = true;
      _lastDetailsAt = DateTime.now();
      _pollFailures = 0;
      _socketReady = realtime?.isReady == true;
      if (_socketReady) {
        _socketReconciled = true;
      }

      if (_routeVisible && _appForeground) {
        unawaited(_markReadNow());
      }
      _syncSyncTimers();
    } catch (_) {
      if (isClosed || revision != _loadRevision) return;
      emit(
        state.copyWith(
          loading: false,
          refreshing: false,
          error: ChatStrings.messagesLoadFailed,
        ),
      );
    }
  }

  Future<void> _loadOlderMessages() async {
    if (isClosed || !isCurrentAccount()) return;
    final cursor = state.nextBefore;
    if (cursor == null) return;
    final revision = _loadRevision;
    emit(state.copyWith(loadingMore: true, clearError: true));
    try {
      final page = await repository.listMessages(
        conversationId,
        before: cursor,
        limit: _pageSize,
      );
      if (isClosed || revision != _loadRevision || !isCurrentAccount()) return;

      final older = chronologicalMessagesFromBackend(page.items);
      final merged = _mergeMessages(existing: state.messages, incoming: older);
      emit(
        state.copyWith(
          messages: merged,
          loadingMore: false,
          hasMore: page.hasMore,
          nextBefore: page.nextBefore,
          clearNextBefore: page.nextBefore == null,
          clearError: true,
        ),
      );
    } catch (_) {
      if (isClosed || revision != _loadRevision) return;
      emit(
        state.copyWith(
          loadingMore: false,
          error: ChatStrings.messagesLoadFailed,
        ),
      );
    }
  }

  Future<void> _markReadNow() async {
    if (isClosed ||
        !isCurrentAccount() ||
        !_routeVisible ||
        !_appForeground ||
        _markingRead) {
      return;
    }
    _markingRead = true;
    try {
      await repository.markRead(conversationId);
      if (isClosed || !isCurrentAccount()) return;
      if (!state.markedRead) {
        emit(state.copyWith(markedRead: true));
      }
      onMarkedRead?.call();
    } catch (_) {
      // Leave unread state unchanged when mark-read fails.
    } finally {
      _markingRead = false;
    }
  }

  /// Returns `true` when the backend confirmed the message.
  @override
  Future<bool> sendMessage(String text) async {
    final trimmed = text.trim();
    if (!canSend || trimmed.isEmpty) return false;
    if (trimmed.runes.length > 2000) {
      if (!isClosed) {
        emit(state.copyWith(error: ChatStrings.sendFailed));
      }
      return false;
    }

    final sendVersion = ++_sendVersion;
    setComposerTyping(false);
    emit(state.copyWith(sending: true, clearError: true));
    try {
      final confirmed = await repository.sendMessage(
        conversationId,
        text: trimmed,
      );
      if (isClosed || sendVersion != _sendVersion || !isCurrentAccount()) {
        return false;
      }
      _appendConfirmed(chatMessageFromBackend(confirmed));
      emit(state.copyWith(sending: false, clearError: true));
      return true;
    } on DioException catch (error) {
      if (isClosed || sendVersion != _sendVersion) return false;
      await _reconcileSendRestriction(error);
      emit(
        state.copyWith(
          sending: false,
          error: state.canSend
              ? ChatStrings.sendFailed
              : state.restrictionLabel,
        ),
      );
      return false;
    } catch (_) {
      if (isClosed || sendVersion != _sendVersion) return false;
      emit(state.copyWith(sending: false, error: ChatStrings.sendFailed));
      return false;
    }
  }

  @override
  Future<List<ChatMessage>> sendAttachments(List<GalleryAttachment> selected) =>
      _sendImages(selected);

  @override
  Future<ChatMessage?> sendVoice(String path, Duration duration) async {
    if (!isClosed) {
      emit(state.copyWith(error: ChatStrings.unsupportedAttachment));
    }
    return null;
  }

  @override
  ChatMessage? sendLocation(ChatLocation location) {
    if (!isClosed) {
      emit(state.copyWith(error: ChatStrings.unsupportedAttachment));
    }
    return null;
  }

  Future<List<ChatMessage>> _sendImages(
    List<GalleryAttachment> selected,
  ) async {
    if (!canSend || selected.isEmpty || mediaStore == null) return [];
    final sendVersion = ++_sendVersion;
    emit(state.copyWith(sendingMedia: true, clearError: true));

    List<ChatAttachment> prepared = [];
    final confirmed = <ChatMessage>[];
    try {
      prepared = await mediaStore!.prepare(selected);
      if (isClosed ||
          sendVersion != _sendVersion ||
          !state.canSend ||
          !isCurrentAccount()) {
        await mediaStore!.discard(prepared);
        if (!isClosed) emit(state.copyWith(sendingMedia: false));
        return [];
      }

      for (final file in prepared) {
        if (file.type != ChatAttachmentType.image) {
          throw const FormatException('unsupported');
        }
        final path = file.path;
        final message = await repository.sendImageMessage(
          conversationId,
          File(path),
        );
        if (isClosed || sendVersion != _sendVersion || !isCurrentAccount()) {
          await mediaStore!.discard(prepared);
          if (!isClosed) emit(state.copyWith(sendingMedia: false));
          return confirmed;
        }
        final mapped = chatMessageFromBackend(message);
        confirmed.add(mapped);
        _appendConfirmed(mapped);
      }

      try {
        await mediaStore!.discard(prepared);
      } catch (_) {}
      if (!isClosed) {
        emit(state.copyWith(sendingMedia: false, clearError: true));
      }
      return confirmed;
    } on DioException catch (error) {
      try {
        await mediaStore?.discard(prepared);
      } catch (_) {}
      if (isClosed || sendVersion != _sendVersion) return confirmed;
      await _reconcileSendRestriction(error);
      emit(
        state.copyWith(
          sendingMedia: false,
          error: state.canSend
              ? AppStrings.mediaSendFailed
              : state.restrictionLabel,
        ),
      );
      return confirmed;
    } catch (_) {
      try {
        await mediaStore?.discard(prepared);
      } catch (_) {}
      if (!isClosed && sendVersion == _sendVersion) {
        emit(
          state.copyWith(
            sendingMedia: false,
            error: AppStrings.mediaSendFailed,
          ),
        );
      }
      return confirmed;
    }
  }

  void _appendConfirmed(ChatMessage message) {
    if (isClosed) return;
    final merged = _mergeMessages(
      existing: state.messages,
      incoming: [message],
    );
    emit(state.copyWith(messages: merged));
  }

  List<ChatMessage> _mergeMessages({
    required List<ChatMessage> existing,
    required List<ChatMessage> incoming,
  }) {
    final byId = <String, ChatMessage>{
      for (final message in existing) message.id: _applyLocalDelete(message),
    };
    for (final message in incoming) {
      final next = _applyLocalDelete(message);
      final prior = byId[next.id];
      if (prior != null && prior.deleted && !next.deleted) {
        byId[next.id] = prior;
        continue;
      }
      if (prior != null &&
          prior.deliveryStatus == ChatDeliveryStatus.read &&
          next.deliveryStatus == ChatDeliveryStatus.sent) {
        // Monotonic read ticks — stale REST without readAt must not regress.
        byId[next.id] = next.copyWith(deliveryStatus: ChatDeliveryStatus.read);
      } else {
        byId[next.id] = next;
      }
    }
    if (_peerReadAt != null) {
      final readAtUtc = _peerReadAt!.toUtc();
      for (final entry in byId.entries.toList()) {
        final message = entry.value;
        if (message.isMine &&
            !message.deleted &&
            !message.sentAt.toUtc().isAfter(readAtUtc) &&
            message.deliveryStatus != ChatDeliveryStatus.read) {
          byId[entry.key] = message.copyWith(
            deliveryStatus: ChatDeliveryStatus.read,
          );
        }
      }
    }
    final ordered = byId.values.toList()
      ..sort((a, b) {
        final byTime = a.sentAt.compareTo(b.sentAt);
        if (byTime != 0) return byTime;
        return a.id.compareTo(b.id);
      });
    return List.unmodifiable(ordered);
  }

  ChatMessage _applyLocalDelete(ChatMessage message) {
    if (!_locallyDeleted.contains(message.id) && !message.deleted) {
      return message;
    }
    _rememberLocalDelete(message.id);
    if (message.deleted &&
        message.text.isEmpty &&
        message.imageUrl == null &&
        message.attachment == null) {
      return message;
    }
    return message.copyWith(
      deleted: true,
      text: '',
      clearImageUrl: true,
      clearAttachment: true,
    );
  }

  @override
  void startSelection([String? id]) {
    if (state.visibleMessages.isEmpty || state.sendingMedia || state.sending) {
      return;
    }
    emit(state.copyWith(selectionMode: true, selected: id == null ? {} : {id}));
  }

  @override
  void toggleSelection(String id) {
    if (!state.messages.any((message) => message.id == id)) return;
    final selected = {...state.selected};
    if (!selected.add(id)) selected.remove(id);
    emit(
      state.copyWith(selectionMode: true, selected: Set.unmodifiable(selected)),
    );
  }

  @override
  void selectAll() => emit(
    state.copyWith(
      selectionMode: true,
      selected: Set.unmodifiable(
        state.messages
            .where((message) => message.isMine && !message.deleted)
            .map((message) => message.id),
      ),
    ),
  );

  @override
  void cancelSelection() =>
      emit(state.copyWith(selectionMode: false, selected: {}));

  @override
  Future<void> deleteSelected() async {
    if (state.selected.isEmpty || state.sendingMedia || state.sending) return;
    if (!isCurrentAccount()) return;

    final ids = state.selected
        .where((id) {
          final message = state.messages
              .where((item) => item.id == id)
              .firstOrNull;
          return message != null && message.isMine && !message.deleted;
        })
        .toList(growable: false);
    if (ids.isEmpty) {
      emit(state.copyWith(selectionMode: false, selected: {}));
      return;
    }

    try {
      for (final id in ids) {
        await repository.deleteMessage(conversationId, id);
        if (!isCurrentAccount()) return;
        _rememberLocalDelete(id);
      }
      if (isClosed) return;
      final updated = [
        for (final message in state.messages)
          ids.contains(message.id)
              ? _applyLocalDelete(message.copyWith(deleted: true))
              : message,
      ];
      emit(
        state.copyWith(
          messages: List.unmodifiable(updated),
          selectionMode: false,
          selected: {},
          clearError: true,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(error: ChatStrings.deleteFailed));
      }
    }
  }

  @override
  Future<void> clearMessages() async {
    if (!isClosed) {
      emit(state.copyWith(error: ChatStrings.clearUnavailable));
    }
  }

  @override
  Future<void> setBlocked(bool blocked) async {
    final peerId = state.peerUserId;
    final profiles = this.profiles;
    final me = currentUserId();
    if (peerId == null ||
        profiles == null ||
        me == null ||
        me.isEmpty ||
        !isCurrentAccount()) {
      if (!isClosed) {
        emit(state.copyWith(error: ChatStrings.sendFailed));
      }
      return;
    }

    _sendVersion++;
    try {
      if (blocked) {
        await profiles.block(
          peerId,
          currentUserId: me,
          isCurrentAccount: isCurrentAccount,
        );
      } else {
        await profiles.unblock(peerId, isCurrentAccount: isCurrentAccount);
      }
      if (isClosed || !isCurrentAccount()) return;
      await _refreshPermissions();
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(error: ChatStrings.sendFailed));
      }
    }
  }

  Future<void> _refreshPermissions({bool silent = false}) async {
    if (isClosed || !isCurrentAccount()) return;
    try {
      final detail = await repository.getChat(conversationId);
      if (isClosed || !isCurrentAccount()) return;
      final unchanged =
          state.blocked == detail.iBlocked &&
          state.canSend == detail.canSend &&
          state.cannotSendReason == detail.cannotSendReason &&
          state.peerUserId == detail.user.id &&
          _sameWarnings(state.warnings, detail.warnings);
      if (unchanged && silent) return;
      emit(
        state.copyWith(
          blocked: detail.iBlocked,
          canSend: detail.canSend,
          cannotSendReason: detail.cannotSendReason,
          clearCannotSendReason: detail.cannotSendReason == null,
          peerUserId: detail.user.id,
          warnings: detail.warnings,
          selected: silent ? state.selected : {},
          selectionMode: silent ? state.selectionMode : false,
          clearError: true,
        ),
      );
    } catch (_) {
      // Keep prior permissions when reconciliation fails.
    }
  }

  bool _sameWarnings(List<BackendChatWarning> a, List<BackendChatWarning> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].message != b[i].message) return false;
    }
    return true;
  }

  Future<void> _reconcileSendRestriction(DioException error) async {
    final status = error.response?.statusCode;
    if (status == 403 || status == 409 || status == 422) {
      await _refreshPermissions();
    }
  }
}
