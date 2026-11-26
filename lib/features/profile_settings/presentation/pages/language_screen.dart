import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';

import '../widgets/common/settings_page.dart';
import '../widgets/language/language_options.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});
  @override
  Widget build(BuildContext context) => const SettingsPage(
    title: ProfileSettingsStrings.language,
    child: LanguageOptions(),
  );
}
