import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class MyTeamsHeader extends StatelessWidget implements PreferredSizeWidget {
  const MyTeamsHeader({super.key, required this.onCreate});
  final VoidCallback onCreate;
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
  @override
  Widget build(BuildContext context) => AppBar(
    leading: IconButton(
      tooltip: 'Create team',
      onPressed: onCreate,
      icon: const AppIcon(AppIcons.add, size: 26),
    ),
    title: const Align(
      alignment: Alignment.centerRight,
      child: Text(
        'MyTeam',
        textAlign: TextAlign.right,
        style: AppTextStyles.screenTitle,
      ),
    ),
    actions: [
      IconButton(
        tooltip: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
        icon: const RotatedBox(
          quarterTurns: 2,
          child: AppIcon(AppIcons.back, size: 20),
        ),
      ),
    ],
  );
}
