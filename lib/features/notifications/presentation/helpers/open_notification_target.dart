import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:hywork/features/dashboard/presentation/cubit/dashboard_navigation_cubit.dart';
import 'package:hywork/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/notifications/presentation/helpers/push_open_target.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

/// Opens an existing destination for a backend notification target.
///
/// Supported:
/// - `post` → post detail
/// - `chat` → conversation (`GET /chats/{id}`)
/// - `user` → start/open chat with that user (`POST /chats`)
/// - `order` → cart tab (orders live under cart until a dedicated order screen)
Future<void> openNotificationTarget(
  BuildContext context,
  AppNotification notification,
) async {
  final type = notification.targetType?.trim();
  final id = notification.targetId?.trim();
  if (type == null || type.isEmpty || id == null || id.isEmpty) {
    AppToast.info(context, NotificationStrings.openUnsupported);
    return;
  }

  switch (type) {
    case NotificationTargetType.post:
      await _openPost(context, id);
    case NotificationTargetType.chat:
      await openChatById(context, id);
    case NotificationTargetType.user:
      await _openUser(context, id);
    case NotificationTargetType.order:
      _openOrders(context);
    default:
      AppToast.info(context, NotificationStrings.openUnsupported);
  }
}

/// Opens a destination from documented FCM `data` fields.
///
/// Returns `true` when a concrete screen was opened; `false` when the caller
/// should fall back to the notifications inbox.
Future<bool> openPushOpenTarget(
  BuildContext context,
  PushOpenTarget target,
) async {
  final chatId = target.chatId;
  if (chatId != null) {
    await openChatById(context, chatId);
    return true;
  }

  final postId = target.postId;
  if (postId != null) {
    await _openPost(context, postId);
    return true;
  }

  final userId = target.userId;
  if (userId != null) {
    await _openUser(context, userId);
    return true;
  }

  if (target.isOrder) {
    _openOrders(context);
    return true;
  }

  return false;
}

Future<void> _openPost(BuildContext context, String id) async {
  if (!ProfileCategory.isBackendId(id)) {
    AppToast.warning(context, NotificationStrings.openFailed);
    return;
  }
  final repository = context.read<ApiPostsRepository?>();
  if (repository == null) {
    AppToast.warning(context, NotificationStrings.openFailed);
    return;
  }
  try {
    final post = await repository.loadDetail(id);
    if (!context.mounted) return;
    openPublishedHomePost(context, post);
  } catch (_) {
    if (context.mounted) {
      AppToast.warning(context, NotificationStrings.openFailed);
    }
  }
}

Future<void> _openUser(BuildContext context, String userId) async {
  if (!ProfileCategory.isBackendId(userId)) {
    AppToast.warning(context, NotificationStrings.openFailed);
    return;
  }
  await openSellerConversation(
    context,
    PostSeller(id: userId, name: '', avatarAsset: ''),
  );
}

void _openOrders(BuildContext context) {
  final dashboard =
      context.read<DashboardNavigationCubit?>() ??
      DashboardNavigationCubit.active;
  if (dashboard == null || dashboard.isClosed) {
    AppToast.info(context, NotificationStrings.openUnsupported);
    return;
  }
  // Pop notification routes so the dashboard cart tab is visible.
  Navigator.of(context).popUntil((route) => route.isFirst);
  unawaited(dashboard.openTab(DashboardTab.cart));
}
