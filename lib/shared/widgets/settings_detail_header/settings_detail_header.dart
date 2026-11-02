import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// Shared header for the profile and location settings previews.
class SettingsDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const SettingsDetailHeader({super.key, required this.title});
  final String title;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    centerTitle: false,
    titleSpacing: 0,
    leading: IconButton(
      tooltip: AppStrings.back,
      onPressed: () => Navigator.of(context).pop(),
      icon: const AppIcon(AppIcons.back, size: 20),
    ),
    title: Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        textAlign: TextAlign.right,
      ),
    ),
    actions: [
      IconButton(
        tooltip: AppStrings.done,
        onPressed: () {
          FocusScope.of(context).unfocus();
          Navigator.of(context).pop();
        },
        icon: const AppIcon(AppIcons.check, size: 22),
      ),
      const SizedBox(width: 8),
    ],
  );
}
