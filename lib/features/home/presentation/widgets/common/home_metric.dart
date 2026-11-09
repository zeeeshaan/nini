import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/localization/app_strings.dart';

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
    return Semantics(
      button: onTap != null,
      toggled: selected,
      child: Tooltip(
        message: label,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                Text(
                  AppStrings.persianDigits(count),
                  style: AppTextStyles.notificationBadge,
                ),
                const SizedBox(width: 3),
                icon,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
