import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';

import '../widgets/common/settings_empty_state.dart';
import '../widgets/common/settings_page.dart';

class CommentsScreen extends StatelessWidget {
  const CommentsScreen({super.key});
  @override
  Widget build(BuildContext context) => const SettingsPage(
    title: ProfileSettingsStrings.comments,
    child: SettingsEmptyState(
      title: ProfileSettingsStrings.noCommentHistory,
      message: ProfileSettingsStrings.commentsHelp,
      icon: AppIcons.postComment,
    ),
  );
}
