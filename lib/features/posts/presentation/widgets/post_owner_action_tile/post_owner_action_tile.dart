import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_colors.dart';

class PostOwnerActionTile extends StatelessWidget {
  const PostOwnerActionTile({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.destructive = false,
  });
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool destructive;
  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: destructive ? AppColors.red : null),
    title: Text(
      label,
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      style: destructive ? const TextStyle(color: AppColors.red) : null,
    ),
    onTap: onTap,
  );
}
