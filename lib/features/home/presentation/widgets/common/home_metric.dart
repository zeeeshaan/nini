import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/post_detail_strings.dart';

class HomeMetric extends StatelessWidget {
  const HomeMetric({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.onTap,
    this.selected,
  });

  final String label;
  final String count;
  final Widget icon;
  final VoidCallback? onTap;
  final bool? selected;

  @override
  Widget build(BuildContext context) {
    // Keep engagement counts in Persian, including legacy formatted values.
    final displayedCount = PostDetailStrings.persianDigits(
      AppStrings.persianDigits(count),
    ).replaceAll(',', '٬');
    return Semantics(
      button: onTap != null,
      toggled: selected,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 44,
              minWidth: onTap == null ? 0 : 44,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                textDirection: TextDirection.ltr,
                children: [
                  Flexible(
                    child: Text(
                      displayedCount,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.labelEmphasis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 3),
                  icon,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
