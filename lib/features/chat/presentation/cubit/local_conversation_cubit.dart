import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/domain/repositories/chat_messages_repository.dart';
import 'package:hywork/features/chat/domain/services/chat_media_store.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:hywork/features/create_post/domain/models/gallery_attachment.dart';

/// Local/in-memory conversation path used by team chat and tests.
///
/// Production peer chat uses [ConversationCubit] + [ApiChatsRepository].
class LocalConversationCubit extends ConversationController {
  LocalConversationCubit({
    required this.conversationId,
    required this.repository,
    this.mediaStore,
  }) : super(
         ConversationState(
           messages: repository.getMessages(conversationId),
           blocked: repository.isBlocked(conversationId),
           canSend: !repository.isBlocked(conversationId),
         ),
       );

  final String conversationId;
  final ChatMessagesRepository repository;
  final ChatMediaStore? mediaStore;
  int _sequence = 0;
  int _sendVersion = 0;

  @override
  bool get canSend =>
      !isClosed &&
      !state.blocked &&
      !repository.isBlocked(conversationId) &&
      !state.sendingMedia;

  @override
  ChatMessage? get latestMessage =>
      state.messages.isEmpty ? null : state.messages.last;

  @override
  void showEmoji(bool visible) =>
      emit(state.copyWith(emojiVisible: visible, error: state.error));

  @override
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

  @override
  Future<bool> sendMessage(String text) async {
    if (!canSend || text.trim().isEmpty) return false;
    final message = _message(text: text.trim());
    repository.addMessage(message);
    emit(state.copyWith(messages: repository.getMessages(conversationId)));
    return true;
  }

  @override
  ChatMessage? sendLocation(ChatLocation location) {
    if (!canSend || !location.isValid) return null;
    final message = _message(location: location);
    repository.addMessage(message);
    emit(state.copyWith(messages: repository.getMessages(conversationId)));
    return message;
  }

  @override
  Future<List<ChatMessage>> sendAttachments(List<GalleryAttachment> selected) =>
      _sendPrepared(
        () => mediaStore!.prepare(selected),
        empty: selected.isEmpty,
      );

  @override
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

  @override
  void startSelection([String? id]) {
    if (state.messages.isEmpty || state.sendingMedia) return;
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
      selected: Set.unmodifiable(state.messages.map((message) => message.id)),
    ),
  );

  @override
  void cancelSelection() =>
      emit(state.copyWith(selectionMode: false, selected: {}));

  @override
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
    } catch (_) {}
  }

  @override
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
    } catch (_) {}
  }

  @override
  Future<void> setBlocked(bool blocked) async {
    if (blocked) _sendVersion++;
    repository.setBlocked(conversationId, blocked);
    emit(
      state.copyWith(
        blocked: blocked,
        canSend: !blocked,
        selected: {},
        selectionMode: false,
      ),
    );
  }

  @override
  Future<void> load() async {}

  @override
  Future<void> loadOlder() async {}

  @override
  void setLifecycle({required bool visible, required bool foreground}) {}
}
