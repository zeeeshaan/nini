import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/theme/app_colors.dart';

class ProfileCategoryChip extends StatelessWidget {
  const ProfileCategoryChip({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.count,
  });

  final String label;
  final bool isSelected;
  final VoidCallback? onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      selected: isSelected,
      value: count?.toString(),
      child: Material(
        color: AppColors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              color: isSelected
                  ? Theme.of(context).colorScheme.surfaceContainerHighest
                  : Theme.of(context).colorScheme.surface,
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.outline,
                width: 1,
              ),
            ),
            child: Text(
              label,
              textDirection: TextDirection.ltr,
              maxLines: 1,
              softWrap: false,
              textScaler: MediaQuery.textScalerOf(context),
              style: AppTextStyles.body.copyWith(height: 1.4),
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ),
    );
  }
}
