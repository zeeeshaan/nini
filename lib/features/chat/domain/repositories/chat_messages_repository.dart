import 'package:hywork/features/chat/domain/models/chat_message.dart';

abstract class ChatMessagesRepository {
  List<ChatMessage> getMessages(String conversationId);

  void addMessage(ChatMessage message);

  void clearMessages(String conversationId);
  void deleteMessages(String conversationId, Set<String> messageIds);
  bool isBlocked(String conversationId);
  void setBlocked(String conversationId, bool blocked);

  /// Null means this conversation has not been opened in this session.
  List<ChatMessage>? existingMessages(String conversationId);
}
