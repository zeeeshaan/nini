import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/notification_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class NotificationHeader extends StatelessWidget {
  const NotificationHeader({super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 4, 16, 14),
    child: Row(
      textDirection: TextDirection.ltr,
      children: [
        const Expanded(
          child: Text(
            NotificationStrings.title,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: AppTextStyles.screenTitle,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: AppStrings.back,
          onPressed: () => Navigator.of(context).pop(),
          icon: const AppIcon(AppIcons.backRight, size: 24),
        ),
      ],
    ),
  );
}
