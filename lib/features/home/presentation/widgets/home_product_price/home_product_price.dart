import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';

import 'package:nini/features/home/presentation/widgets/home_badge/home_badge.dart';

class HomeProductPrice extends StatelessWidget {
  const HomeProductPrice({super.key});

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 10,
        children: [
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            runSpacing: 4,
            children: [
              const RotatedBox(
                quarterTurns: 3,
                child: Text(AppStrings.toman, style: AppTextStyles.micro),
              ),
              const SizedBox(width: 2),
              Text(
                AppStrings.persianDigits('12,000'),
                style: AppTextStyles.productPrice,
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.persianDigits('13,000'),
                style: AppTextStyles.bodyText.copyWith(
                  color: foreground.withValues(alpha: .3),
                  decoration: TextDecoration.lineThrough,
                ),
              ),
            ],
          ),
          HomeBadge(
            label: AppStrings.inStock(2),
            background: AppColors.stockBadgeBackground,
            foreground: AppColors.notificationBadge,
          ),
        ],
      ),
    );
  }
}
