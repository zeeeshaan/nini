import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/features/profile_settings/presentation/widgets/common/theme_options.dart';
import 'package:hywork/features/profile_settings/presentation/widgets/common/settings_detail_header.dart';

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
