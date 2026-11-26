import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/create_post/presentation/widgets/dialogs/post_dialog.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/settings_media_item.dart';
import '../../helpers/open_settings_post.dart';

Future<void> showSettingsMediaActions(
  BuildContext context,
  SettingsMediaItem item,
) async {
  final edit = await showPostDialog<bool>(
    context,
    PostDialog(
      title: AppStrings.moreOptions,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text(
              ProfileSettingsStrings.viewPost,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
            trailing: const AppIcon(AppIcons.grid),
            onTap: () => Navigator.of(context).pop(false),
          ),
          ListTile(
            title: const Text(
              ProfileSettingsStrings.editPost,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
            trailing: const AppIcon(AppIcons.edit),
            onTap: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    ),
  );
  if (edit != null && context.mounted) {
    openSettingsPost(context, item.post, edit: edit);
  }
}
