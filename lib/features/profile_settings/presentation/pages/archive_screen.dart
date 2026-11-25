import 'package:flutter/material.dart';
import 'package:nini/core/constants/app_icons/app_icons.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';

import '../widgets/common/settings_empty_state.dart';
import '../widgets/common/settings_page.dart';

class ArchiveScreen extends StatelessWidget {
  const ArchiveScreen({super.key});
  @override
  Widget build(BuildContext context) => const SettingsPage(
    title: ProfileSettingsStrings.archive,
    child: SettingsEmptyState(
      textAlign: TextAlign.center,
      title: ProfileSettingsStrings.noArchive,
      message: ProfileSettingsStrings.archiveHelp,
      icon: AppIcons.bookmark,
    ),
  );
}
