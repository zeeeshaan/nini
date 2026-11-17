import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostFormOptionTile extends StatelessWidget {
  const PostFormOptionTile({
    super.key,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
  });

  final String label;
  final String? value;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: colors.outline, width: 0.8),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              const AppIcon(AppIcons.back, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      label,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (value?.isNotEmpty == true) ...[
                      const SizedBox(height: 2),
                      Text(
                        value!,
                        textDirection: TextDirection.ltr,
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 6), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}
