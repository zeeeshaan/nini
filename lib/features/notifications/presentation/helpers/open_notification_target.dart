import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/notification_strings.dart';
import 'package:hywork/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:hywork/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:hywork/features/notifications/domain/app_notification.dart';
import 'package:hywork/features/notifications/domain/backend_notification.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

/// Opens an existing destination for a backend notification target.
///
/// Supported: `post` via existing post detail flow; `chat` via `GET /chats/{id}`
/// using [AppNotification.targetId] (chat id, not notification id).
/// `user` requires a username route that Swagger target ids do not provide.
/// `order` has no backend receipt screen wired yet.
Future<void> openNotificationTarget(
  BuildContext context,
  AppNotification notification,
) async {
  final type = notification.targetType;
  final id = notification.targetId?.trim();
  if (type == null || id == null || id.isEmpty) return;

  switch (type) {
    case NotificationTargetType.post:
      await _openPost(context, id);
    case NotificationTargetType.chat:
      await openChatById(context, id);
    case NotificationTargetType.user:
    case NotificationTargetType.order:
      AppToast.info(context, NotificationStrings.openUnsupported);
    default:
      AppToast.info(context, NotificationStrings.openUnsupported);
  }
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
