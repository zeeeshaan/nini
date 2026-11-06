import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/domain/repositories/chat_messages_repository.dart';
import 'package:nini/features/chat/domain/services/chat_media_store.dart';
import 'package:nini/features/create_post/domain/models/gallery_attachment.dart';

class ConversationState {
  const ConversationState({
    required this.messages,
    this.blocked = false,
    this.sendingMedia = false,
    this.selectionMode = false,
    this.emojiVisible = false,
    this.pickingAttachment = false,
    this.selected = const {},
    this.error,
  });
  final List<ChatMessage> messages;
  final bool blocked, sendingMedia, selectionMode;
  final bool emojiVisible, pickingAttachment;
  final Set<String> selected;
  final String? error;
  ConversationState copyWith({
    List<ChatMessage>? messages,
    bool? blocked,
    bool? sendingMedia,
    bool? selectionMode,
    bool? emojiVisible,
    bool? pickingAttachment,
    Set<String>? selected,
    String? error,
  }) => ConversationState(
    messages: messages ?? this.messages,
    blocked: blocked ?? this.blocked,
    sendingMedia: sendingMedia ?? this.sendingMedia,
    selectionMode: selectionMode ?? this.selectionMode,
    emojiVisible: emojiVisible ?? this.emojiVisible,
    pickingAttachment: pickingAttachment ?? this.pickingAttachment,
    selected: selected ?? this.selected,
    error: error,
  );
}

class ConversationCubit extends Cubit<ConversationState> {
  ConversationCubit({
    required this.conversationId,
    required this.repository,
    this.mediaStore,
  }) : super(
         ConversationState(
           messages: repository.getMessages(conversationId),
           blocked: repository.isBlocked(conversationId),
         ),
       );
  final String conversationId;
  final ChatMessagesRepository repository;
  final ChatMediaStore? mediaStore;
  int _sequence = 0;
  int _sendVersion = 0;
  bool get canSend =>
      !isClosed &&
      !state.blocked &&
      !repository.isBlocked(conversationId) &&
      !state.sendingMedia;
  ChatMessage? get latestMessage =>
      state.messages.isEmpty ? null : state.messages.last;

  void showEmoji(bool visible) =>
      emit(state.copyWith(emojiVisible: visible, error: state.error));
  void pickingAttachment(bool busy) =>
      emit(state.copyWith(pickingAttachment: busy, error: state.error));

  ChatMessage _message({
    String text = '',
    ChatAttachment? attachment,
    ChatLocation? location,
  }) {
    final now = DateTime.now();
    return ChatMessage(
      id: '${now.microsecondsSinceEpoch}_${_sequence++}',
      conversationId: conversationId,
      text: text,
      attachment: attachment,
      location: location,
      sentAt: now,
      isMine: true,
    );
  }

  ChatMessage? sendMessage(String text) {
    if (!canSend || text.trim().isEmpty) return null;
    final message = _message(text: text.trim());
    repository.addMessage(message);
    emit(state.copyWith(messages: repository.getMessages(conversationId)));
    return message;
  }

  ChatMessage? sendLocation(ChatLocation location) {
    if (!canSend || !location.isValid) return null;
    final message = _message(location: location);
    repository.addMessage(message);
    emit(state.copyWith(messages: repository.getMessages(conversationId)));
    return message;
  }

  Future<List<ChatMessage>> sendAttachments(List<GalleryAttachment> selected) =>
      _sendPrepared(
        () => mediaStore!.prepare(selected),
        empty: selected.isEmpty,
      );
  Future<ChatMessage?> sendVoice(String path, Duration duration) async {
    final sent = await _sendPrepared(
      () async => [await mediaStore!.prepareVoice(path, duration)],
    );
    return sent.isEmpty ? null : sent.single;
  }

  Future<List<ChatMessage>> _sendPrepared(
    Future<List<ChatAttachment>> Function() prepare, {
    bool empty = false,
  }) async {
    if (!canSend || empty || mediaStore == null) return [];
    final sendVersion = ++_sendVersion;
    emit(state.copyWith(sendingMedia: true));
    List<ChatAttachment> files = [];
    try {
      files = await prepare();
      if (isClosed ||
          sendVersion != _sendVersion ||
          state.blocked ||
          repository.isBlocked(conversationId)) {
        await mediaStore!.discard(files);
        if (!isClosed) emit(state.copyWith(sendingMedia: false));
        return [];
      }
      final messages = files.map((file) => _message(attachment: file)).toList();
      for (final message in messages) {
        repository.addMessage(message);
      }
      emit(
        state.copyWith(
          messages: repository.getMessages(conversationId),
          sendingMedia: false,
        ),
      );
      return messages;
    } catch (_) {
      if (files.isNotEmpty) {
        try {
          await mediaStore!.discard(files);
        } catch (_) {}
      }
      if (!isClosed) {
        emit(
          state.copyWith(
            sendingMedia: false,
            error: sendVersion == _sendVersion
                ? AppStrings.mediaSendFailed
                : null,
          ),
        );
      }
      return [];
    }
  }

  void startSelection([String? id]) {
    if (state.messages.isEmpty || state.sendingMedia) return;
    emit(state.copyWith(selectionMode: true, selected: id == null ? {} : {id}));
  }

  void toggleSelection(String id) {
    if (!state.messages.any((message) => message.id == id)) return;
    final selected = {...state.selected};
    if (!selected.add(id)) selected.remove(id);
    emit(
      state.copyWith(selectionMode: true, selected: Set.unmodifiable(selected)),
    );
  }

  void selectAll() => emit(
    state.copyWith(
      selectionMode: true,
      selected: Set.unmodifiable(state.messages.map((message) => message.id)),
    ),
  );
  void cancelSelection() =>
      emit(state.copyWith(selectionMode: false, selected: {}));
  Future<void> deleteSelected() async {
    if (state.selected.isEmpty || state.sendingMedia) return;
    final files = state.messages
        .where((message) => state.selected.contains(message.id))
        .map((message) => message.attachment)
        .whereType<ChatAttachment>()
        .toList();
    repository.deleteMessages(conversationId, state.selected);
    emit(
      state.copyWith(
        messages: repository.getMessages(conversationId),
        selectionMode: false,
        selected: {},
      ),
    );
    try {
      await mediaStore?.discard(files);
    } catch (_) {
      /* Cache cleanup does not undo a successful deletion. */
    }
  }

  Future<void> clearMessages() async {
    if (state.sendingMedia) return;
    final files = state.messages
        .map((message) => message.attachment)
        .whereType<ChatAttachment>()
        .toList();
    repository.clearMessages(conversationId);
    emit(state.copyWith(messages: [], selected: {}, selectionMode: false));
    try {
      await mediaStore?.discard(files);
    } catch (_) {
      /* OS cache cleanup can retry later. */
    }
  }

  void setBlocked(bool blocked) {
    if (blocked) _sendVersion++;
    repository.setBlocked(conversationId, blocked);
    emit(state.copyWith(blocked: blocked, selected: {}, selectionMode: false));
  }
}
