import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/localization/strings/chat_strings.dart';
import 'package:hywork/features/chat/data/api_chats_repository.dart';
import 'package:hywork/features/chat/data/backend_chat_mapper.dart';
import 'package:hywork/features/chat/utils/push_chat_conversation.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
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
    await pushChatConversation(
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
    await pushChatConversation(
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
