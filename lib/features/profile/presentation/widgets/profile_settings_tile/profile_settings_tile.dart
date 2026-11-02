import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// Settings row with optional navigation to a completed detail preview.
class ProfileSettingsTile extends StatelessWidget {
  const ProfileSettingsTile({super.key, required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => ListTile(
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 22),
    minTileHeight: 52,
    leading: const AppIcon(AppIcons.back, size: 16),
    title: Text(
      label,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: const TextStyle(fontSize: 15),
    ),
  );
}
