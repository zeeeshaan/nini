import 'package:flutter/material.dart';

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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const RotatedBox(
                quarterTurns: 3,
                child: Text('تومان', style: TextStyle(fontSize: 8)),
              ),
              const SizedBox(width: 2),
              Text(
                AppStrings.persianDigits('12,000'),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                AppStrings.persianDigits('13,000'),
                style: TextStyle(
                  fontSize: 14,
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
