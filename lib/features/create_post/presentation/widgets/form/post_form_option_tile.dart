import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

class PostFormOptionTile extends StatelessWidget {
  const PostFormOptionTile({
    super.key,
    required this.label,
    this.onTap,
    this.value,
    this.trailing,
    this.footer,
    this.hasError = false,
  });

  final String label;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Widget? footer;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final hasValue = value?.isNotEmpty == true;
    final showValueUnderLabel = footer == null && hasValue;
    final labelColor = showValueUnderLabel || footer != null
        ? null
        : colors.onSurface.withValues(alpha: .35);

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasError ? colors.error : colors.outline,
              width: 0.8,
            ),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          label,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.right,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: labelColor,
                          ),
                        ),
                        if (showValueUnderLabel) ...[
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
                  const SizedBox(width: 10),
                  const AppIcon(AppIcons.back, size: 18),
                  if (trailing != null) ...[
                    const SizedBox(width: 6),
                    trailing!,
                  ],
                ],
              ),
              if (footer != null) ...[const SizedBox(height: 10), footer!],
            ],
          ),
        ),
      ),
    );
  }
}
