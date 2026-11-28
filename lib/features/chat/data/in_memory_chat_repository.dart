import 'package:hywork/features/chat/domain/models/chat_message.dart';
import 'package:hywork/features/chat/domain/models/chat_conversation.dart';
import 'package:hywork/features/chat/domain/repositories/chat_messages_repository.dart';

/// Local/team chat store. Starts empty — no demo conversations or messages.
class InMemoryChatRepository implements ChatMessagesRepository {
  InMemoryChatRepository._();
  InMemoryChatRepository.empty();

  static final InMemoryChatRepository instance = InMemoryChatRepository._();

  final Map<String, List<ChatMessage>> _messages = {};
  final Set<String> _blocked = {};
  final Map<String, ChatConversation> _conversations = {};
  String? _accountId;
  final _accounts =
      <
        String,
        ({
          Map<String, List<ChatMessage>> messages,
          Set<String> blocked,
          Map<String, ChatConversation> conversations,
        })
      >{};

  /// Detach private state on logout; preserve unsynchronized work for its owner.
  void useAccount(String? accountId) {
    if (_accountId == accountId) return;
    final previous = _accountId;
    if (previous != null) {
      _accounts[previous] = (
        messages: Map.of(_messages),
        blocked: Set.of(_blocked),
        conversations: Map.of(_conversations),
      );
    }
    _messages.clear();
    _blocked.clear();
    _conversations.clear();
    _accountId = accountId;
    final saved = _accounts.remove(accountId);
    if (saved != null) {
      _messages.addAll(saved.messages);
      _blocked.addAll(saved.blocked);
      _conversations.addAll(saved.conversations);
    }
  }

  List<ChatConversation> get conversations =>
      List.unmodifiable(_conversations.values);
  Set<String> get blockedConversationIds => Set.unmodifiable(_blocked);

  ChatConversation openConversation(ChatConversation conversation) {
    _messages.putIfAbsent(conversation.id, () => []);
    return _conversations.putIfAbsent(conversation.id, () => conversation);
  }

  @override
  List<ChatMessage> getMessages(String conversationId) {
    final messages = _messages.putIfAbsent(conversationId, () => []);
    return List.unmodifiable(messages);
  }

  @override
  void addMessage(ChatMessage message) {
    if (isBlocked(message.conversationId)) {
      throw StateError('Conversation blocked');
    }
    _messages.putIfAbsent(message.conversationId, () => []).add(message);
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
}
