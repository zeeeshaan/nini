import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/chat/domain/backend_chat.dart';
import 'package:hywork/features/chat/domain/models/chat_message.dart';

String chatMessagePreview(ChatMessage? message) {
  if (message == null) return AppStrings.noMessages;
  if (message.deleted) return ChatStrings.messageDeleted;
  if (message.location != null) return AppStrings.location;
  if (message.text.isNotEmpty) return message.text;
  if (message.imageUrl != null && message.imageUrl!.trim().isNotEmpty) {
    return AppStrings.photo;
  }
  if (message.type == BackendChatMessageType.system) {
    return AppStrings.noMessages;
  }
  return switch (message.attachment?.type) {
    ChatAttachmentType.image => AppStrings.photo,
    ChatAttachmentType.video => AppStrings.video,
    ChatAttachmentType.voice => AppStrings.voiceMessage,
    ChatAttachmentType.file => message.attachment!.name,
    null => AppStrings.noMessages,
  };
}
