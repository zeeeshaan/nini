import 'package:flutter/material.dart';

import 'package:nini/core/theme/app_text_styles.dart';

class TeamHeader extends StatelessWidget implements PreferredSizeWidget {
  const TeamHeader({super.key, required this.onSave, required this.onBack});

  final VoidCallback onSave;
  final VoidCallback onBack;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground = theme.colorScheme.onSurface;

    return AppBar(
      backgroundColor: theme.scaffoldBackgroundColor,
      foregroundColor: foreground,
      elevation: 0,
      leading: IconButton(
        tooltip: "ایجاد تیم",
        icon: const Icon(Icons.check),
        onPressed: onSave,
      ),
      title: Align(
        alignment: Alignment.centerRight,
        child: Text(
          "ایجاد تیم",
          textAlign: TextAlign.right,
          style: AppTextStyles.bodyText.copyWith(
            color: foreground,
            fontWeight: FontWeight.w600,
          ),
          textDirection: TextDirection.rtl,
        ),
      ),
      actions: [
        IconButton(
          tooltip: "بازگشت",
          icon: const Icon(Icons.chevron_right),
          onPressed: onBack,
        ),
      ],
    );
  }
}
