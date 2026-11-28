import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/features/create_post/widgets/post_dialog/post_dialog.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

enum TeamOption { edit, delete, chat }

class TeamOptionsSheet extends StatelessWidget {
  const TeamOptionsSheet({super.key});
  @override
  Widget build(BuildContext context) => PostDialog(
    title: 'More Options',
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final option in TeamOption.values)
          ListTile(
            title: Text(
              switch (option) {
                TeamOption.edit => 'Edit',
                TeamOption.delete => 'Delete',
                TeamOption.chat => 'Chat',
              },
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
            trailing: AppIcon(switch (option) {
              TeamOption.edit => AppIcons.edit,
              TeamOption.delete => AppIcons.trash,
              TeamOption.chat => AppIcons.chat,
            }, size: 22),
            onTap: () => Navigator.of(context).pop(option),
          ),
      ],
    ),
  );
}
