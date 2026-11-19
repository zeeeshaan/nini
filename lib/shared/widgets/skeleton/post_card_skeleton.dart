import 'package:flutter/material.dart';

import 'app_shimmer.dart';

/// The feed card uses a 43px author avatar followed by a full-width square image.
class PostCardSkeleton extends StatelessWidget {
  const PostCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context);
    return AppShimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppSkeletonBox(
                        width: 125,
                        height: scale.scale(12),
                        radius: 4,
                      ),
                      const SizedBox(height: 5),
                      AppSkeletonBox(
                        width: 75,
                        height: scale.scale(9),
                        radius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const AppSkeletonBox(width: 43, height: 43, isCircle: true),
              ],
            ),
          ),
          const AspectRatio(
            aspectRatio: 1,
            child: AppSkeletonBox(height: double.infinity, radius: 0),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (var i = 0; i < 5; i++)
                  const AppSkeletonBox(width: 24, height: 24, radius: 5),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AppSkeletonBox(width: 190, height: scale.scale(14), radius: 4),
                const SizedBox(height: 8),
                AppSkeletonBox(width: 95, height: scale.scale(10), radius: 4),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppSkeletonBox(
                    width: 90,
                    height: scale.scale(15),
                    radius: 4,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: .5),
        ],
      ),
    );
  }
}
