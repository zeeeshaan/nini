import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class DetailsSkeleton extends StatelessWidget {
  const DetailsSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final theme = Theme.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      final width = math.min(responsive.width, 720.0);
      final padding = math.min(responsive.horizontalPadding, width / 8);
      final contentWidth = width - padding * 2;
      final avatarSize = math.min(46.0, contentWidth / 4);
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
                child: Padding(
                  padding: EdgeInsets.all(padding),
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
                                  width: 135,
                                  height: textScaler.scale(14),
                                ),
                                const SizedBox(height: 9),
                                AppSkeletonBox(
                                  width: 85,
                                  height: textScaler.scale(10),
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
                      const SizedBox(height: 20),
                      const AspectRatio(
                        aspectRatio: 4 / 3,
                        child: AppSkeletonBox(
                          width: double.infinity,
                          height: double.infinity,
                          radius: 14,
                        ),
                      ),
                      const SizedBox(height: 20),
                      AppSkeletonBox(width: 200, height: textScaler.scale(17)),
                      const SizedBox(height: 14),
                      AppSkeletonBox(
                        width: double.infinity,
                        height: textScaler.scale(12),
                      ),
                      const SizedBox(height: 9),
                      AppSkeletonBox(
                        width: double.infinity,
                        height: textScaler.scale(12),
                      ),
                      const SizedBox(height: 9),
                      AppSkeletonBox(width: 180, height: textScaler.scale(12)),
                      const SizedBox(height: 24),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      Wrap(
                        textDirection: TextDirection.ltr,
                        alignment: WrapAlignment.end,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          AppSkeletonBox(
                            width: 90,
                            height: textScaler.scale(16),
                          ),
                          AppSkeletonBox(
                            width: 115,
                            height: textScaler.scale(12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      const Wrap(
                        textDirection: TextDirection.ltr,
                        alignment: WrapAlignment.end,
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          AppSkeletonBox(width: 44, height: 30, radius: 8),
                          AppSkeletonBox(width: 44, height: 30, radius: 8),
                          AppSkeletonBox(width: 44, height: 30, radius: 8),
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
