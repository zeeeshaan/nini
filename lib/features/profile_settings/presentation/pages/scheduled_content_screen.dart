import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';

import '../widgets/common/settings_page.dart';
import '../widgets/common/settings_posts_content.dart';
import '../widgets/scheduled_content/scheduled_posts_list.dart';

class ScheduledContentScreen extends StatelessWidget {
  const ScheduledContentScreen({super.key});
  @override
  Widget build(BuildContext context) => SettingsPage(
    title: ProfileSettingsStrings.scheduledContent,
    child: SettingsPostsContent(
      builder: (context, posts) => ScheduledPostsList(posts: posts),
    ),
  );
}
