import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

import '../cubit/posts_cubit.dart';
import '../pages/edit_post_screen.dart';
import '../widgets/actions/post_delete_sheet.dart';
import '../widgets/actions/post_owner_actions_sheet.dart';

/// Coordinates menu routes. Widgets display state; repositories own mutations.
Future<void> managePostActions(
  BuildContext context,
  PostItem post, {
  ValueChanged<PostItem>? onEdit,
}) async {
  if (post.metadata['backend'] == true) {
    await _manageBackendPost(context, post, onEdit: onEdit);
    return;
  }

  final posts = context.read<PostsCubit>();
  // Refresh cards left in memory by hot reload from the old read-only dataset.
  final visible = posts.state.find(post.id);
  if (visible != null &&
      visible.media.isEmpty &&
      visible.imageAsset.isNotEmpty &&
      !posts.state.isBusy) {
    await posts.load();
    if (!context.mounted) return;
  }
  if (!posts.state.canManage(post) || posts.state.isBusy) return;
  final action = await showPostOwnerActions(context);
  if (!context.mounted || action == null || !posts.state.canManage(post)) {
    return;
  }
  final current = posts.state.find(post.id)!;
  switch (action) {
    case PostOwnerAction.edit:
      if (onEdit != null) {
        onEdit(current);
        return;
      }
      await Navigator.of(context).push<PostItem>(
        MaterialPageRoute(builder: (_) => EditPostScreen(post: current)),
      );
      return;
    case PostOwnerAction.delete:
      final deleted = await showPostDeleteConfirmation(context, current);
      if (context.mounted && deleted) Navigator.of(context).pop();
    case PostOwnerAction.resubmit:
      return;
  }
}

Future<void> _manageBackendPost(
  BuildContext context,
  PostItem post, {
  ValueChanged<PostItem>? onEdit,
}) async {
  final repository = context.read<ApiPostsRepository>();
  final status = post.metadata['backendStatus'] as String?;
  final editable = status == null ||
      const {
        'published',
        'pending_review',
        'changes_requested',
      }.contains(status);
  final action = await showPostOwnerActions(
    context,
    allowEdit: editable,
    allowResubmit: status == 'changes_requested',
  );
  if (!context.mounted || action == null) return;

  switch (action) {
    case PostOwnerAction.edit:
      if (onEdit != null) {
        onEdit(post);
        return;
      }
      final updated = await Navigator.of(context).push<PostItem>(
        MaterialPageRoute(
          builder: (_) => BackendEditPostScreen(postId: post.id),
        ),
      );
      if (!context.mounted) return;
      if (updated != null) {
        final feed = context.read<FeedCubit?>();
        final own = context.read<OwnPostsCubit?>();
        if (feed != null) unawaited(feed.refreshFromServer());
        if (own != null) unawaited(own.refresh());
        Navigator.of(context).pop(updated);
      }
      return;
    case PostOwnerAction.delete:
      MyServerPost owned;
      try {
        owned = await repository.loadOwnedPost(post.id);
      } catch (error) {
        if (context.mounted) {
          AppToast.error(
            context,
            error is PostApiException
                ? error.message
                : 'This post is unavailable.',
          );
        }
        return;
      }
      if (!context.mounted) return;
      final deleted = await showPostDeleteConfirmation(
        context,
        post,
        onBackendDelete: () => repository.deleteOwnedPost(owned),
      );
      if (!context.mounted || !deleted) return;
      final feed = context.read<FeedCubit?>();
      final own = context.read<OwnPostsCubit?>();
      feed?.removePost(post.id);
      if (feed != null) unawaited(feed.refreshFromServer());
      if (own != null) unawaited(own.refresh());
      AppToast.success(context, 'Post deleted.');
      Navigator.of(context).pop();
      return;
    case PostOwnerAction.resubmit:
      try {
        final owned = await repository.loadOwnedPost(post.id);
        await repository.resubmitOwnedPost(owned);
        if (!context.mounted) return;
        final own = context.read<OwnPostsCubit?>();
        if (own != null) unawaited(own.refresh());
        AppToast.success(context, 'Post updated successfully.');
      } catch (error) {
        if (context.mounted) {
          AppToast.error(
            context,
            error is PostApiException
                ? error.message
                : 'Could not resubmit the post.',
          );
        }
      }
  }
}
