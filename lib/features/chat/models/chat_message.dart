import 'package:hywork/features/chat/models/chat_attachment.dart';
import 'package:hywork/features/chat/models/chat_location.dart';

export 'package:hywork/features/chat/models/chat_attachment.dart';
export 'package:hywork/features/chat/models/chat_location.dart';

enum ChatDeliveryStatus { sent, read }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.text,
    required this.sentAt,
    required this.isMine,
    this.deliveryStatus = ChatDeliveryStatus.sent,
    this.attachment,
    this.location,
    this.deleted = false,
    this.type = 'text',
    this.imageUrl,
  });

  final String id;
  final String conversationId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final ChatDeliveryStatus deliveryStatus;
  final ChatAttachment? attachment;
  final ChatLocation? location;
  final bool deleted;
  final String type;
  final String? imageUrl;

  bool get hasImage =>
      !deleted &&
      ((imageUrl != null && imageUrl!.trim().isNotEmpty) ||
          (attachment != null && attachment!.type == ChatAttachmentType.image));

  ChatMessage copyWith({
    String? text,
    bool? deleted,
    String? imageUrl,
    bool clearImageUrl = false,
    ChatAttachment? attachment,
    bool clearAttachment = false,
    ChatDeliveryStatus? deliveryStatus,
  }) {
    return ChatMessage(
      id: id,
      conversationId: conversationId,
      text: text ?? this.text,
      sentAt: sentAt,
      isMine: isMine,
      deliveryStatus: deliveryStatus ?? this.deliveryStatus,
      attachment: clearAttachment ? null : (attachment ?? this.attachment),
      location: location,
      deleted: deleted ?? this.deleted,
      type: type,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
    );
  }
}
