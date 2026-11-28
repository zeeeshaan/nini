import '../app_string/app_string.dart';

/// English interface text for Chat Phase 2 REST integration.
abstract final class ChatStrings {
  static const loadFailed = 'Could not load chats. Please try again.';
  static const messagesLoadFailed =
      'Could not load messages. Please try again.';
  static const sendFailed = 'Could not send the message. Try again.';
  static const deleteFailed = 'Could not delete the message. Try again.';
  static const openFailed = 'Could not open this chat. Try again.';
  static const markReadFailed = 'Could not mark the chat as read.';
  static const markAllReadPartial =
      'Some chats could not be marked as read. Pull to refresh.';
  static const signInRequired = 'Sign in to view chats.';
  static const typing = 'Typing…';
  static const typingFa = 'در حال نوشتن…';
  static const unsupportedAttachment =
      'Only JPG, PNG or WebP photos up to 5 MB can be sent.';

  /// Localized typing status for the existing conversation header subtitle slot.
  static String typingLabel({required bool english}) =>
      english ? typing : typingFa;
  static const clearUnavailable =
      'Clearing a conversation is not available yet.';
  /// No `DELETE /chats/{id}` in Swagger 0.20.0 — never invent a local hide.
  static const deleteChatUnavailable =
      'Deleting a chat is not supported by the server yet.';

  /// Swagger soft-delete: own message stays as `deleted: true` with no text;
  /// peers are notified via `chat:message_deleted`.
  static const deleteMyMessageHelp = 'This removes your message from the chat.';
  static const cannotSendBlockedByHywork =
      'Messaging is temporarily restricted by HyWork.';
  static const cannotSendYouBlocked =
      'You blocked this user. Unblock to send messages.';
  static const cannotSendUserBlockedYou =
      'You cannot message this user right now.';
  static const cannotSendUserUnavailable =
      'This user is unavailable for messaging.';
  static const cannotSendGeneric = 'You cannot send messages in this chat.';

  static String cannotSendReason(String? reason) {
    switch (reason) {
      case 'blocked_by_hywork':
        return cannotSendBlockedByHywork;
      case 'you_blocked_user':
        return cannotSendYouBlocked;
      case 'user_blocked_you':
        return cannotSendUserBlockedYou;
      case 'user_unavailable':
        return cannotSendUserUnavailable;
      default:
        return cannotSendGeneric;
    }
  }

  static String unreadConversationCount(int count) =>
      AppStrings.unreadMessageCount(count);
}
