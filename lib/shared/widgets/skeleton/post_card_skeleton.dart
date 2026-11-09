import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final theme = Theme.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      final width = math.min(responsive.width, 650.0);
      final padding = math.min(
        responsive.adaptive<double>(compact: 12, medium: 16, expanded: 16),
        width / 8,
      );
      final contentWidth = width - padding * 2;
      final avatarSize = math.min(42.0, contentWidth / 4);
      final headerGap = math.min(12.0, contentWidth / 8);

      return Align(
        alignment: Alignment.topCenter,
        heightFactor: 1,
        child: SizedBox(
          width: width,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.topRight,
            child: SizedBox(
              width: width,
              child: AppShimmer(
                child: Container(
                  padding: EdgeInsets.all(padding),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: .4,
                      ),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    textDirection: TextDirection.ltr,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        textDirection: TextDirection.ltr,
                        children: [
                          Expanded(
                            child: Column(
                              textDirection: TextDirection.ltr,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppSkeletonBox(
                                  width: 125,
                                  height: textScaler.scale(12),
                                ),
                                const SizedBox(height: 8),
                                AppSkeletonBox(
                                  width: 75,
                                  height: textScaler.scale(9),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: headerGap),
                          AppSkeletonBox(
                            width: avatarSize,
                            height: avatarSize,
                            isCircle: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const AspectRatio(
                        aspectRatio: 4 / 3,
                        child: AppSkeletonBox(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 12,
                        ),
                      ),
                      const SizedBox(height: 14),
                      AppSkeletonBox(
                        width: double.infinity,
                        height: textScaler.scale(12),
                      ),
                      const SizedBox(height: 8),
                      AppSkeletonBox(width: 210, height: textScaler.scale(12)),
                      const SizedBox(height: 16),
                      const Wrap(
                        textDirection: TextDirection.ltr,
                        alignment: WrapAlignment.end,
                        spacing: 18,
                        runSpacing: 8,
                        children: [
                          AppSkeletonBox(width: 38, height: 18),
                          AppSkeletonBox(width: 38, height: 18),
                          AppSkeletonBox(width: 38, height: 18),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
