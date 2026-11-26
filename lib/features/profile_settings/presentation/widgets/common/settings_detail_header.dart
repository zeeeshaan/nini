import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Shared header for the profile and location settings previews.
class SettingsDetailHeader extends StatelessWidget
    implements PreferredSizeWidget {
  const SettingsDetailHeader({
    super.key,
    required this.title,
    this.onDone,
    this.enabled = true,
    this.saving = false,
  });
  final String title;
  final VoidCallback? onDone;
  final bool enabled, saving;
  @override
  Size get preferredSize => const Size.fromHeight(56);
  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: false,
    centerTitle: false,
    titleSpacing: 0,
    title: Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textDirection: TextDirection.ltr,
        style: AppTextStyles.settingsDetailTitle,
        textAlign: TextAlign.right,
      ),
    ),
    leading: IconButton(
      tooltip: AppStrings.done,
      onPressed: !enabled || saving
          ? null
          : () {
              FocusScope.of(context).unfocus();
              if (onDone != null) {
                onDone!();
              } else {
                Navigator.of(context).pop();
              }
            },
      icon: saving
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const AppIcon(AppIcons.check, size: 22),
    ),
    actions: [
      IconButton(
        tooltip: AppStrings.back,
        onPressed: saving ? null : () => Navigator.of(context).pop(),
        icon: const AppIcon(AppIcons.backRight, size: 20),
      ),
    ],
  );
}
