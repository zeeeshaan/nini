import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/models/chat_conversation.dart';
import 'package:hywork/features/chat/models/chat_message.dart';
import 'package:hywork/features/chat/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/screens/conversation_screen.dart';
import 'package:hywork/features/chat/utils/chat_account_scope.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';

/// Pushes a production peer [ConversationScreen] with account-scoped DI.
///
/// Resolves account-scoped repositories from context when not overridden.
/// Captures [ChatAccountScope] at push time so the conversation stays bound
/// to the account that opened it.
Future<T?> pushChatConversation<T extends Object?>(
  BuildContext context, {
  required ChatConversation conversation,
  String? subtitle,
  ApiChatsRepository? repository,
  ApiPublicProfileRepository? profiles,
  bool Function()? isCurrentAccount,
  String? Function()? currentUserId,
  VoidCallback? onMarkedRead,
  ValueChanged<ChatMessage?>? onLatestMessageChanged,
  bool allowBlocking = true,
  Widget? headerTitle,
  PreferredSizeWidget? headerBottom,
}) {
  final scope = captureChatAccountScope(context.read<SessionCubit?>());
  final chats = repository ?? context.read<ApiChatsRepository>();
  final profileRepo = profiles ?? context.read<ApiPublicProfileRepository?>();
  final unread = context.read<ChatUnreadCubit?>();

  bool current() {
    if (isCurrentAccount != null) return isCurrentAccount();
    return scope?.isCurrent() ?? false;
  }

  String? userId() {
    if (currentUserId != null) return currentUserId();
    return scope?.currentUserId();
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversation: conversation,
        subtitle: subtitle,
        repository: chats,
        profiles: profileRepo,
        isCurrentAccount: current,
        currentUserId: userId,
        allowBlocking: allowBlocking,
        headerTitle: headerTitle,
        headerBottom: headerBottom,
        onMarkedRead:
            onMarkedRead ??
            () {
              unread?.applyConversationRead();
              unread?.refresh();
            },
        onLatestMessageChanged: onLatestMessageChanged,
      ),
    ),
  );
}
