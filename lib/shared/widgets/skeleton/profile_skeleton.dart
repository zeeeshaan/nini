import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

/// Header placeholders; post grids have their own loading state and geometry.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key, this.seller = false});

  final bool seller;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final avatar = seller
          ? responsive.adaptive<double>(
              compact: 104,
              medium: 124,
              expanded: 136,
            )
          : responsive.adaptive<double>(compact: 80, medium: 96, expanded: 104);
      final textScale = MediaQuery.textScalerOf(context);
      return AppShimmer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      for (var i = 0; i < 3; i++)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                AppSkeletonBox(
                                  width: 32,
                                  height: textScale.scale(14),
                                  radius: 3,
                                ),
                                const SizedBox(height: 10),
                                AppSkeletonBox(
                                  width: 50,
                                  height: textScale.scale(10),
                                  radius: 3,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AppSkeletonBox(width: avatar, height: avatar, isCircle: true),
              ],
            ),
            const SizedBox(height: 8),
            AppSkeletonBox(width: 145, height: textScale.scale(16), radius: 3),
            const SizedBox(height: 6),
            AppSkeletonBox(width: 95, height: textScale.scale(11), radius: 3),
          ],
        ),
      );
    },
  );
}
