import 'package:flutter/material.dart';
import 'package:nini/core/localization/profile_settings_strings.dart';
import 'package:nini/features/profile_settings/presentation/widgets/accessibility_screen_widgets/theme_options/theme_options.dart';
import 'package:nini/features/profile_settings/presentation/widgets/settings_detail_header/settings_detail_header.dart';

class AccessibilityScreen extends StatelessWidget {
  const AccessibilityScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const SettingsDetailHeader(
      title: ProfileSettingsStrings.accessibility,
    ),
    body: SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: const SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
            child: ThemeOptions(),
          ),
        ),
      ),
    ),
  );
}
