import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

/// Settings row with optional navigation to a completed detail preview.
class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({
    super.key,
    required this.label,
    this.onTap,
    this.icon = AppIcons.back,
    this.trailingIcon,
  });
  final String label;
  final VoidCallback? onTap;
  final String icon;
  final String? trailingIcon;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
    minTileHeight: 52,
    leading: AppIcon(icon, size: 16),
    trailing: trailingIcon != null ? AppIcon(trailingIcon!, size: 28) : null,
    title: Text(
      label,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
      style: AppTextStyles.settingsLabel,
    ),
  );
}
