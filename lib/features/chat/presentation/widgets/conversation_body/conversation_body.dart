import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:nini/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:nini/features/chat/presentation/widgets/emoji_panel/chat_emoji_panel.dart';
import 'package:nini/features/chat/presentation/widgets/message_bubble/chat_message_bubble.dart';
import 'package:nini/features/chat/presentation/widgets/message_composer/chat_message_composer.dart';
import 'package:nini/features/chat/presentation/widgets/voice_recording/voice_recording_panel.dart';

class ConversationBody extends StatelessWidget {
  const ConversationBody({
    super.key,
    required this.conversation,
    required this.recording,
    required this.scrollController,
    required this.messageController,
    required this.messageFocusNode,
    required this.emojiVisible,
    required this.onUnblock,
    required this.onStartSelection,
    required this.onSelect,
    required this.onOpenAttachment,
    required this.onCancelRecording,
    required this.onStopRecording,
    required this.onSendVoice,
    required this.onSend,
    required this.onRecord,
    required this.onEmoji,
    required this.onKeyboard,
    required this.onFiles,
    required this.onPhotos,
    this.pickingAttachment = false,
  });
  final ConversationState conversation;
  final VoiceRecordingState recording;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool emojiVisible, pickingAttachment;
  final ValueChanged<String> onStartSelection, onSelect;
  final VoidCallback onUnblock,
      onOpenAttachment,
      onCancelRecording,
      onStopRecording,
      onSendVoice,
      onSend,
      onRecord,
      onEmoji,
      onKeyboard,
      onFiles,
      onPhotos;
  @override
  Widget build(BuildContext context) {
    final recordingActive = recording.phase != VoiceRecordingPhase.idle;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (conversation.blocked)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.personBlocked,
                      textDirection: TextDirection.rtl,
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => onUnblock(),
                    child: const Text(AppStrings.unblockPerson),
                  ),
                ],
              ),
            ),
          if (conversation.selectionMode)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Text(AppStrings.selectMessagesHelp),
            ),
          Expanded(
            child: conversation.messages.isEmpty
                ? const Center(child: Text(AppStrings.noMessages))
                : ListView.builder(
                    controller: scrollController,
                    reverse: true,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    itemCount: conversation.messages.length,
                    itemBuilder: (context, index) {
                      final message = conversation
                          .messages[conversation.messages.length - 1 - index];
                      return ChatMessageBubble(
                        key: ValueKey(message.id),
                        message: message,
                        selected: conversation.selected.contains(message.id),
                        selectionMode: conversation.selectionMode,
                        onLongPress:
                            recordingActive ||
                                conversation.sendingMedia ||
                                pickingAttachment
                            ? null
                            : () => onStartSelection(message.id),
                        onSelect: () => onSelect(message.id),
                        onOpenAttachment: () => onOpenAttachment(),
                      );
                    },
                  ),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: math.max(60, constraints.maxHeight - 60),
            ),
            child: SingleChildScrollView(
              child: recordingActive
                  ? VoiceRecordingPanel(
                      state: recording,
                      sending: conversation.sendingMedia,
                      onCancel: onCancelRecording,
                      onStop: onStopRecording,
                      onSend: onSendVoice,
                    )
                  : ChatMessageComposer(
                      controller: messageController,
                      focusNode: messageFocusNode,
                      onSend: onSend,
                      onRecord: onRecord,
                      onEmojiPressed: onEmoji,
                      onAttachmentPressed: () => onFiles(),
                      onPhotosPressed: () => onPhotos(),
                      onKeyboardRequested: onKeyboard,
                      enabled:
                          !conversation.blocked &&
                          !conversation.selectionMode &&
                          !pickingAttachment,
                      busy: conversation.sendingMedia,
                      emojiVisible: emojiVisible,
                    ),
            ),
          ),
          if (emojiVisible &&
              MediaQuery.viewInsetsOf(context).bottom == 0 &&
              !conversation.blocked &&
              !conversation.selectionMode &&
              !recordingActive)
            ChatEmojiPanel(
              controller: messageController,
              height: math.min(280, math.max(0, constraints.maxHeight - 140)),
            ),
        ],
      ),
    );
  }
}
