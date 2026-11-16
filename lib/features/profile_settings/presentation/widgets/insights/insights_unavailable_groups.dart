import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_settings_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class InsightsUnavailableGroups extends StatelessWidget {
  const InsightsUnavailableGroups({super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final group in const {
        ProfileSettingsStrings.customerStatistics: [
          ProfileSettingsStrings.newFollowers,
          ProfileSettingsStrings.topCustomers,
          ProfileSettingsStrings.feedback,
        ],
        ProfileSettingsStrings.alerts: [
          ProfileSettingsStrings.usageReminder,
          ProfileSettingsStrings.unansweredMessages,
        ],
      }.entries) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Text(
            group.key,
            textAlign: TextAlign.right,
            style: AppTextStyles.sectionTitle,
            textDirection: TextDirection.rtl,
          ),
        ),
        for (final label in group.value)
          ListTile(
            leading: const Text(
              '—',
              style: AppTextStyles.bodyEmphasis,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            title: Text(
              label,
              textAlign: TextAlign.right,
              style: AppTextStyles.body,
              textDirection: TextDirection.rtl,
            ),
            subtitle: const Text(
              ProfileSettingsStrings.backendRequired,
              textAlign: TextAlign.right,
              style: AppTextStyles.helper,
              textDirection: TextDirection.rtl,
            ),
          ),
      ],
    ],
  );
}
