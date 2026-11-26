import 'package:hywork/core/localization/strings/category_strings.dart';
import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';

class CategorySheetActions extends StatelessWidget {
  const CategorySheetActions({
    super.key,
    required this.saving,
    required this.onSubmit,
    this.destructive = false,
    this.submitLabel = ProfilePostStrings.done,
  });
  final bool saving, destructive;
  final String submitLabel;
  final VoidCallback onSubmit;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: saving ? null : () => Navigator.pop(context),
            child: Text(
              CategoryStrings.of(context).text(ProfilePostStrings.cancel),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton(
            style: destructive
                ? FilledButton.styleFrom(
                    backgroundColor: AppColors.red,
                    foregroundColor: AppColors.white,
                  )
                : null,
            onPressed: saving ? null : onSubmit,
            child: Text(
              CategoryStrings.of(context)
                  .text(saving ? ProfilePostStrings.saving : submitLabel),
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.right,
            ),
          ),
        ),
      ],
    );
  }
}
