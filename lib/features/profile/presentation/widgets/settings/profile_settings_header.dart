import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/core/localization/strings/profile_settings_strings.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class ProfileSettingsHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const ProfileSettingsHeader({super.key});
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    title: const Align(
      alignment: Alignment.centerRight,
      child: Text(
        ProfileSettingsStrings.title,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: AppTextStyles.screenTitle,
      ),
    ),
    leading: IconButton(
      tooltip: ProfileScreenStrings.done,
      onPressed: () => Navigator.of(context).pop(),
      icon: const AppIcon(AppIcons.check, size: 25),
    ),
    actions: [
      IconButton(
        tooltip: ProfileScreenStrings.back,
        onPressed: () => Navigator.of(context).pop(),
        icon: const AppIcon(AppIcons.backRight, size: 24),
      ),
    ],
  );
}
