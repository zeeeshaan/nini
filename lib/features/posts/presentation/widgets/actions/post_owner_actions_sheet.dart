import 'package:flutter/material.dart';
import 'package:nini/core/localization/persian_feature.dart';
import 'package:nini/core/localization/profile_post_strings.dart';

import 'post_owner_action_tile.dart';

enum PostOwnerAction { edit, delete }

Future<PostOwnerAction?> showPostOwnerActions(BuildContext context) =>
    showModalBottomSheet<PostOwnerAction>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const PersianFeature(child: PostOwnerActionsSheet()),
    );

class PostOwnerActionsSheet extends StatelessWidget {
  const PostOwnerActionsSheet({super.key});
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PostOwnerActionTile(
            label: ProfilePostStrings.editPost,
            icon: Icons.edit_outlined,
            onTap: () => Navigator.of(context).pop(PostOwnerAction.edit),
          ),
          PostOwnerActionTile(
            label: ProfilePostStrings.deletePost,
            icon: Icons.delete_outline,
            destructive: true,
            onTap: () => Navigator.of(context).pop(PostOwnerAction.delete),
          ),
        ],
      ),
    ),
  );
}
