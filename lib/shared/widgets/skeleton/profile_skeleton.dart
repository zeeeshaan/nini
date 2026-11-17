import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final theme = Theme.of(context);
      final textScaler = MediaQuery.textScalerOf(context);
      final width = math.min(responsive.width, 650.0);
      final padding = math.min(responsive.horizontalPadding, width / 8);
      final contentWidth = width - padding * 2;
      final avatarSize = math.min(76.0, contentWidth / 4);
      final headerGap = math.min(16.0, contentWidth / 8);
      final columns = (contentWidth / 110).floor().clamp(
        1,
        responsive.gridColumns.clamp(1, 3),
      );

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
                                  width: 145,
                                  height: textScaler.scale(14),
                                ),
                                const SizedBox(height: 10),
                                AppSkeletonBox(
                                  width: 95,
                                  height: textScaler.scale(11),
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
                      AppSkeletonBox(
                        width: double.infinity,
                        height: textScaler.scale(11),
                      ),
                      const SizedBox(height: 9),
                      AppSkeletonBox(width: 220, height: textScaler.scale(11)),
                      const SizedBox(height: 22),
                      Wrap(
                        textDirection: TextDirection.ltr,
                        alignment: WrapAlignment.end,
                        spacing: 28,
                        runSpacing: 12,
                        children: [
                          for (var index = 0; index < 3; index++)
                            _ProfileStatSkeleton(textScaler: textScaler),
                        ],
                      ),
                      const SizedBox(height: 22),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      // Only the grid uses RTL ordering, matching profile posts.
                      Directionality(
                        textDirection: TextDirection.ltr,
                        child: GridView.builder(
                          primary: false,
                          padding: EdgeInsets.zero,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: columns,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                          itemCount: 6,
                          itemBuilder: (_, _) => const AppSkeletonBox(
                            width: double.infinity,
                            height: double.infinity,
                            radius: 10,
                          ),
                        ),
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

class _ProfileStatSkeleton extends StatelessWidget {
  const _ProfileStatSkeleton({required this.textScaler});

  final TextScaler textScaler;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    textDirection: TextDirection.ltr,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      AppSkeletonBox(width: 42, height: textScaler.scale(14)),
      const SizedBox(height: 8),
      AppSkeletonBox(width: 55, height: textScaler.scale(10)),
    ],
  );
}
