import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';

import '../common/settings_notice.dart';

class LanguageOptions extends StatelessWidget {
  const LanguageOptions({super.key});
  @override
  Widget build(BuildContext context) => ListView(
    children: [
      const SettingsNotice(text: ProfileSettingsStrings.languageHelp),
      RadioGroup<String>(
        groupValue: Localizations.localeOf(context).languageCode,
        onChanged: (_) {},
        child: const Column(
          children: [
            RadioListTile<String>(
              value: 'en',
              enabled: false,
              title: Text(
                ProfileSettingsStrings.english,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
            RadioListTile<String>(
              value: 'fa',
              title: Text(
                ProfileSettingsStrings.persian,
                textAlign: TextAlign.right,
                textDirection: TextDirection.ltr,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
