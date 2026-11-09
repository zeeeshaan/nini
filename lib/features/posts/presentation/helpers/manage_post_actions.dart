import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/shared/models/post/post_item.dart';

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
  }
}
