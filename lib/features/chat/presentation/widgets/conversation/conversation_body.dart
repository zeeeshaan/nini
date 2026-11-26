import 'dart:math' as math;

import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';

import 'package:flutter/material.dart';

import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/features/chat/presentation/cubit/conversation_cubit.dart';
import 'package:hywork/features/chat/presentation/cubit/voice_recording_cubit.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/chat_emoji_panel.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/conversation_empty_state.dart';
import 'package:hywork/features/chat/presentation/widgets/messages/chat_message_bubble.dart';
import 'package:hywork/features/chat/presentation/widgets/conversation/chat_message_composer.dart';
import 'package:hywork/features/chat/presentation/widgets/media/voice_recording_panel.dart';

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
    this.composerEnabled = true,
    this.restrictionLabel,
  });
  final ConversationState conversation;
  final VoiceRecordingState recording;
  final ScrollController scrollController;
  final TextEditingController messageController;
  final FocusNode messageFocusNode;
  final bool emojiVisible, pickingAttachment, composerEnabled;
  final String? restrictionLabel;
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
    final showBlockedBanner = conversation.blocked;
    final showRestriction =
        !conversation.canSend &&
        !showBlockedBanner &&
        restrictionLabel != null &&
        restrictionLabel!.isNotEmpty;
    return LayoutBuilder(
      builder: (context, constraints) => Column(
        children: [
          if (showBlockedBanner)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      AppStrings.personBlocked,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.label,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  TextButton(
                    onPressed: () => onUnblock(),
                    child: const Text(
                      AppStrings.unblockPerson,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          if (showRestriction)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  restrictionLabel!,
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.label,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          if (conversation.selectionMode)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  AppStrings.selectMessagesHelp,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
              ),
            ),
          Expanded(
            child: conversation.messages.isEmpty
                ? const ConversationEmptyState()
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
                                conversation.sending ||
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
              maxHeight: math.max(0, constraints.maxHeight - 60),
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
                      enabled: composerEnabled,
                      busy: conversation.sendingMedia || conversation.sending,
                      emojiVisible: emojiVisible,
                    ),
            ),
          ),
          if (emojiVisible &&
              MediaQuery.viewInsetsOf(context).bottom == 0 &&
              composerEnabled &&
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
