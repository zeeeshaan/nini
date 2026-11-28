import 'package:hywork/core/notifications/push_notifications.dart';
import 'package:hywork/features/chat/cubit/conversation_cubit.dart';

/// Owns Firebase active-conversation registration for one ConversationScreen.
///
/// A newer registration must not be cleared when an older screen disposes —
/// including when both screens share the same conversation id.
class ActiveConversationRegistration {
  ActiveConversationRegistration();

  static int _generation = 0;

  int? _token;
  String? _conversationId;

  /// Test-only: reset generation between cases.
  static void debugResetGeneration() {
    _generation = 0;
  }

  void bind(ConversationCubit conversation) {
    final id = conversation.conversationId;
    final token = ++_generation;
    _token = token;
    _conversationId = id;
    PushNotifications.activeConversationId = id;
    PushNotifications.refreshActiveConversation = () {
      if (_token != token) return Future.value();
      if (PushNotifications.activeConversationId != id) {
        return Future.value();
      }
      return conversation.reconcileSilently();
    };
  }

  void clear() {
    final token = _token;
    final id = _conversationId;
    _token = null;
    _conversationId = null;
    if (token == null || id == null) return;
    if (token != _generation) return;
    if (PushNotifications.activeConversationId != id) return;
    PushNotifications.activeConversationId = null;
    PushNotifications.refreshActiveConversation = null;
  }
}
