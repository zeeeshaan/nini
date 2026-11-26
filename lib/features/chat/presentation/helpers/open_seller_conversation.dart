import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/login/presentation/cubit/session_cubit.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/domain/backend_chat_mapper.dart';
import 'package:hywork/features/chat/domain/models/chat_conversation.dart';
import 'package:hywork/features/chat/presentation/cubit/chat_unread_cubit.dart';
import 'package:hywork/features/chat/presentation/pages/conversation_screen.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/profile/data/api_public_profile_repository.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

final Set<String> _openingUserIds = {};
final Set<String> _openingChatIds = {};

/// Opens the single backend conversation for [seller.id] via `POST /chats`.
Future<void> openSellerConversation(
  BuildContext context,
  PostSeller seller,
) async {
  final userId = seller.id.trim();
  if (!ProfileCategory.isBackendId(userId)) {
    AppToast.warning(context, ChatStrings.openFailed);
    return;
  }
  if (!_openingUserIds.add(userId)) return;

  try {
    final repository = context.read<ApiChatsRepository?>();
    if (repository == null) {
      AppToast.warning(context, ChatStrings.openFailed);
      return;
    }
    final detail = await repository.openChat(userId);
    if (!context.mounted) return;
    await _pushConversation(
      context,
      conversation: chatConversationFromDetail(detail),
      subtitle: seller.location.isEmpty ? null : seller.location,
    );
  } catch (_) {
    if (context.mounted) AppToast.warning(context, ChatStrings.openFailed);
  } finally {
    _openingUserIds.remove(userId);
  }
}

/// Opens an existing backend conversation by chat id (`GET /chats/{id}`).
Future<void> openChatById(
  BuildContext context,
  String chatId, {
  String? subtitle,
}) async {
  final id = chatId.trim();
  if (!ProfileCategory.isBackendId(id)) {
    AppToast.warning(context, ChatStrings.openFailed);
    return;
  }
  if (!_openingChatIds.add(id)) return;

  try {
    final repository = context.read<ApiChatsRepository?>();
    if (repository == null) {
      AppToast.warning(context, ChatStrings.openFailed);
      return;
    }
    final detail = await repository.getChat(id);
    if (!context.mounted) return;
    await _pushConversation(
      context,
      conversation: chatConversationFromDetail(detail),
      subtitle: subtitle,
    );
  } catch (_) {
    if (context.mounted) AppToast.warning(context, ChatStrings.openFailed);
  } finally {
    _openingChatIds.remove(id);
  }
}

Future<void> _pushConversation(
  BuildContext context, {
  required ChatConversation conversation,
  String? subtitle,
}) {
  final chats = context.read<ApiChatsRepository>();
  final profiles = context.read<ApiPublicProfileRepository?>();
  final session = context.read<SessionCubit>();
  final unread = context.read<ChatUnreadCubit?>();
  final initial = session.state;
  bool current() =>
      !session.isClosed &&
      session.state.status == SessionStatus.authenticated &&
      !session.state.isLoggingOut &&
      !session.state.logoutCleanupRequired &&
      session.state.userId != null &&
      session.state.userId == initial.userId &&
      session.state.accountRevision == initial.accountRevision;

  return Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ConversationScreen(
        conversation: conversation,
        subtitle: subtitle,
        repository: chats,
        profiles: profiles,
        isCurrentAccount: current,
        currentUserId: () => current() ? session.state.userId : null,
        onMarkedRead: () {
          unread?.applyConversationRead();
          unread?.refresh();
        },
      ),
    ),
  );
}
