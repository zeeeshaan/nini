import 'package:nini/features/chat/domain/models/chat_attachment.dart';
import 'package:nini/features/chat/domain/models/chat_location.dart';

export 'package:nini/features/chat/domain/models/chat_attachment.dart';
export 'package:nini/features/chat/domain/models/chat_location.dart';

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
  });

  final String id;
  final String conversationId;
  final String text;
  final DateTime sentAt;
  final bool isMine;
  final ChatDeliveryStatus deliveryStatus;
  final ChatAttachment? attachment;
  final ChatLocation? location;
}
