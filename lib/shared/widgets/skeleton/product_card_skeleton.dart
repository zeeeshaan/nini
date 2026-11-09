import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final theme = Theme.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      final padding = math.min(12.0, responsive.width / 8);

      return AppShimmer(
        child: Container(
          width: responsive.width,
          padding: EdgeInsets.all(padding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: .4),
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topRight,
            child: SizedBox(
              width: math.max(0.0, responsive.width - padding * 2 - 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const AspectRatio(
                    aspectRatio: 4 / 3,
                    child: AppSkeletonBox(
                      width: double.infinity,
                      height: double.infinity,
                      radius: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppSkeletonBox(width: 145, height: textScaler.scale(13)),
                  const SizedBox(height: 9),
                  AppSkeletonBox(
                    width: double.infinity,
                    height: textScaler.scale(10),
                  ),
                  const SizedBox(height: 8),
                  AppSkeletonBox(width: 100, height: textScaler.scale(10)),
                  const SizedBox(height: 15),
                  AppSkeletonBox(width: 85, height: textScaler.scale(16)),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}
