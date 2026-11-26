import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/domain/backend_chat_mapper.dart';
import 'package:hywork/features/chat/domain/chat_sync.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/domain/services/chat_media_store.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';
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
}

/// Conversation screen cubit backed by Chat REST with lifecycle polling.
class ConversationCubit extends ConversationController {
  ConversationCubit({
    required this.conversationId,
    required this.repository,
    required this.isCurrentAccount,
    required this.currentUserId,
    this.mediaStore,
    this.profiles,
    this.onMarkedRead,
    this.pollInterval = ChatSync.messagePollInterval,
    this.detailsInterval = ChatSync.detailsPollInterval,
  }) : super(const ConversationState(loading: true)) {
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

  /// Overridable for deterministic tests (production uses [ChatSync]).
  final Duration pollInterval;
  final Duration detailsInterval;

  static const _pageSize = 30;

  int _loadRevision = 0;
  int _sendVersion = 0;
  int _pollGeneration = 0;
  int _pollFailures = 0;
  Future<void>? _loadMoreInFlight;
  Future<void>? _silentInFlight;
  Timer? _pollTimer;
  bool _markingRead = false;
  bool _initialReady = false;
  bool _routeVisible = false;
  bool _appForeground = true;
  DateTime? _lastDetailsAt;
  final Set<String> _locallyDeleted = {};

  bool get _shouldPoll =>
      !isClosed &&
      _initialReady &&
      _routeVisible &&
      _appForeground &&
      isCurrentAccount();

  @visibleForTesting
  bool get isPollingScheduled => _pollTimer != null;

  @visibleForTesting
  Future<void> debugPollOnce({bool refreshDetails = false}) =>
      _silentSync(_pollGeneration, refreshDetails: refreshDetails);

  @override
  bool get canSend =>
      !isClosed &&
      state.canSend &&
      !state.blocked &&
      !state.sending &&
      !state.sendingMedia &&
      isCurrentAccount();

  @override
  ChatMessage? get latestMessage =>
      state.messages.isEmpty ? null : state.messages.last;

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
    final wasActive = _shouldPoll;
    _routeVisible = visible;
    _appForeground = foreground;
    if (!_shouldPoll) {
      _stopPolling(invalidateInFlight: true);
      return;
    }
    if (!wasActive) {
      unawaited(_resumeActive());
    }
  }

  @override
  Future<void> close() {
    _stopPolling(invalidateInFlight: true);
    return super.close();
  }

  void _stopPolling({bool invalidateInFlight = false}) {
    _pollTimer?.cancel();
    _pollTimer = null;
    if (invalidateInFlight) _pollGeneration++;
  }

  Future<void> _resumeActive() async {
    if (!_routeVisible || !_appForeground || !isCurrentAccount() || isClosed) {
      return;
    }
    final generation = ++_pollGeneration;
    _pollTimer?.cancel();
    _pollTimer = null;
    if (!_initialReady) return;
    await _silentSync(generation, refreshDetails: true);
    if (isClosed || generation != _pollGeneration) return;
    await _markReadNow();
    if (isClosed || generation != _pollGeneration || !_shouldPoll) return;
    _scheduleNextPoll(generation);
  }

  void _maybeStartPolling() {
    if (!_shouldPoll) {
      _stopPolling();
      return;
    }
    if (_pollTimer != null || _silentInFlight != null) return;
    _scheduleNextPoll(_pollGeneration);
  }

  Duration _backoffDelay() {
    if (_pollFailures <= 0) return pollInterval;
    final shift = math.min(_pollFailures, 4);
    return pollInterval * (1 << (shift - 1));
  }

  void _scheduleNextPoll(int generation) {
    _pollTimer?.cancel();
    if (isClosed || generation != _pollGeneration || !_shouldPoll) {
      _pollTimer = null;
      return;
    }
    _pollTimer = Timer(_backoffDelay(), () {
      if (isClosed || generation != _pollGeneration) return;
      unawaited(_onPollTick(generation));
    });
  }

  Future<void> _onPollTick(int generation) async {
    if (isClosed || generation != _pollGeneration || !_shouldPoll) return;
    await _silentSync(generation);
    if (isClosed || generation != _pollGeneration) return;
    _scheduleNextPoll(generation);
  }

  Future<void> _silentSync(int generation, {bool refreshDetails = false}) {
    if (_silentInFlight != null) return _silentInFlight!;
    late final Future<void> future;
    future = _runSilentSync(generation, refreshDetails: refreshDetails)
        .whenComplete(() {
          if (identical(_silentInFlight, future)) _silentInFlight = null;
        });
    _silentInFlight = future;
    return future;
  }

  Future<void> _runSilentSync(
    int generation, {
    required bool refreshDetails,
  }) async {
    if (isClosed ||
        generation != _pollGeneration ||
        !_initialReady ||
        !isCurrentAccount()) {
      return;
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
          return;
        }
      }

      final incoming = await _fetchLatestWithGapFill(before);
      if (isClosed || generation != _pollGeneration || !isCurrentAccount()) {
        return;
      }

      final merged = _mergeMessages(
        existing: state.messages,
        incoming: incoming,
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
    } on DioException catch (error) {
      if (isClosed || generation != _pollGeneration) return;
      _pollFailures++;
      final status = error.response?.statusCode;
      if (status == 401) return;
      if (status == 403 || status == 409 || status == 422) {
        await _refreshPermissions(silent: true);
      }
      // Silent: keep conversation visible; no snackbar / loading wipe.
    } catch (_) {
      if (isClosed || generation != _pollGeneration) return;
      _pollFailures++;
    }
  }

  Future<List<ChatMessage>> _fetchLatestWithGapFill(
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

    return chronologicalMessagesFromBackend(collected);
  }

  bool _sameMessages(List<ChatMessage> a, List<ChatMessage> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id ||
          a[i].deleted != b[i].deleted ||
          a[i].text != b[i].text ||
          a[i].imageUrl != b[i].imageUrl) {
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

      if (_routeVisible && _appForeground) {
        unawaited(_markReadNow());
      }
      _maybeStartPolling();
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
      } else {
        byId[next.id] = next;
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
    _locallyDeleted.add(message.id);
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
    if (state.messages.isEmpty || state.sendingMedia || state.sending) return;
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
        _locallyDeleted.add(id);
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
