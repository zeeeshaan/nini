import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

class TeamChatTitle extends StatelessWidget {
  const TeamChatTitle({super.key, required this.name, required this.onTap});
  final String name;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Text(
      name,
      textAlign: TextAlign.right,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: AppTextStyles.pageTitle,
      textDirection: TextDirection.ltr,
    ),
  );
}
