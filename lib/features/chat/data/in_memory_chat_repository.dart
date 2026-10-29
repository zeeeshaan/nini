import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/chat/domain/models/chat_message.dart';
import 'package:nini/features/chat/domain/repositories/chat_messages_repository.dart';

class InMemoryChatRepository implements ChatMessagesRepository {
  InMemoryChatRepository._() : _seedDemo = true;
  InMemoryChatRepository.empty() : _seedDemo = false;
  final bool _seedDemo;

  static final InMemoryChatRepository instance = InMemoryChatRepository._();

  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _blocked = {};

  @override
  List<ChatMessage> getMessages(String conversationId) {
    final messages = _messages.putIfAbsent(
      conversationId,
      () => _createDemoMessages(conversationId),
    );

    return List.unmodifiable(messages);
  }

  @override
  void addMessage(ChatMessage message) {
    if (isBlocked(message.conversationId)) {
      throw StateError('Conversation blocked');
    }
    _messages
        .putIfAbsent(
          message.conversationId,
          () => _createDemoMessages(message.conversationId),
        )
        .add(message);
  }

  @override
  void clearMessages(String conversationId) {
    _messages[conversationId] = [];
  }

  @override
  List<ChatMessage>? existingMessages(String id) =>
      _messages.containsKey(id) ? List.unmodifiable(_messages[id]!) : null;
  @override
  void deleteMessages(String id, Set<String> ids) =>
      _messages[id]?.removeWhere((message) => ids.contains(message.id));
  @override
  bool isBlocked(String id) => _blocked.contains(id);
  @override
  void setBlocked(String id, bool blocked) {
    if (blocked) {
      _blocked.add(id);
    } else {
      _blocked.remove(id);
    }
  }

  List<ChatMessage> _createDemoMessages(String conversationId) {
    if (!_seedDemo) return [];
    final now = DateTime.now();

    return [
      ChatMessage(
        id: '${conversationId}_1',
        conversationId: conversationId,
        text: AppStrings.demoAskAvailability,
        sentAt: now.subtract(const Duration(minutes: 25)),
        isMine: true,
        deliveryStatus: ChatDeliveryStatus.read,
      ),
      ChatMessage(
        id: '${conversationId}_2',
        conversationId: conversationId,
        text: AppStrings.demoConfirmAvailability,
        sentAt: now.subtract(const Duration(minutes: 24)),
        isMine: false,
      ),
      ChatMessage(
        id: '${conversationId}_3',
        conversationId: conversationId,
        text: AppStrings.demoAskDetails,
        sentAt: now.subtract(const Duration(minutes: 22)),
        isMine: true,
        deliveryStatus: ChatDeliveryStatus.read,
      ),
      ChatMessage(
        id: '${conversationId}_4',
        conversationId: conversationId,
        text: AppStrings.demoShareDetails,
        sentAt: now.subtract(const Duration(minutes: 20)),
        isMine: false,
      ),
      ChatMessage(
        id: '${conversationId}_5',
        conversationId: conversationId,
        text: AppStrings.demoThankYou,
        sentAt: now.subtract(const Duration(minutes: 18)),
        isMine: true,
        deliveryStatus: ChatDeliveryStatus.read,
      ),
    ];
  }
}
