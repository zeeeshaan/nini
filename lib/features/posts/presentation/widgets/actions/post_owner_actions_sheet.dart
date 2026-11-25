import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/create_post/presentation/widgets/dialogs/post_dialog.dart';

import 'post_owner_action_tile.dart';

enum PostOwnerAction { edit, delete, resubmit }

Future<PostOwnerAction?> showPostOwnerActions(
  BuildContext context, {
  bool allowEdit = true,
  bool allowResubmit = false,
}) => showAppBottomSheet<PostOwnerAction>(
  context,
  showDragHandle: true,
  builder: (_) =>
      PostOwnerActionsSheet(allowEdit: allowEdit, allowResubmit: allowResubmit),
);

class PostOwnerActionsSheet extends StatelessWidget {
  const PostOwnerActionsSheet({
    super.key,
    this.allowEdit = true,
    this.allowResubmit = false,
  });
  final bool allowEdit, allowResubmit;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (allowEdit)
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
          if (allowResubmit)
            PostOwnerActionTile(
              label: 'Resubmit',
              icon: Icons.send_outlined,
              onTap: () => Navigator.of(context).pop(PostOwnerAction.resubmit),
            ),
        ],
      ),
    ),
  );
}
