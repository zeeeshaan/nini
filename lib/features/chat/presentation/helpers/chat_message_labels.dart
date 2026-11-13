import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';

String chatMessagePreview(ChatMessage? message) {
  if (message == null) return AppStrings.noMessages;
  if (message.location != null) return AppStrings.location;
  if (message.text.isNotEmpty) return message.text;
  return switch (message.attachment?.type) {
    ChatAttachmentType.image => AppStrings.photo,
    ChatAttachmentType.video => AppStrings.video,
    ChatAttachmentType.voice => AppStrings.voiceMessage,
    ChatAttachmentType.file => message.attachment!.name,
    null => AppStrings.noMessages,
  };
}
