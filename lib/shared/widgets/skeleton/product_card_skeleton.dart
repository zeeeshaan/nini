import 'package:flutter/material.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_card.dart';

import 'app_shimmer.dart';

/// Matches the square image and text area of ProfilePostCard.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({
    super.key,
    this.animated = true,
    this.showStatus = false,
  });

  final bool animated;
  final bool showStatus;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final scale = width / ProfilePostCard.referenceWidth;
      final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
      final content = Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AspectRatio(
            aspectRatio: 1,
            child: AppSkeletonBox(height: double.infinity, radius: 0),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                4 * scale,
                4 * scale,
                6 * scale,
                6 * scale,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AppSkeletonBox(
                    width: width * .70,
                    height: 10 * scale * textScale,
                    radius: 3,
                  ),
                  SizedBox(height: 5 * scale),
                  AppSkeletonBox(
                    width: width * .45,
                    height: 8 * scale * textScale,
                    radius: 3,
                  ),
                  if (showStatus) ...[
                    SizedBox(height: 4 * scale),
                    AppSkeletonBox(
                      width: width * .32,
                      height: 8 * scale * textScale,
                      radius: 4,
                    ),
                  ],
                  const Spacer(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: AppSkeletonBox(
                      width: width * .40,
                      height: 12 * scale * textScale,
                      radius: 3,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      return animated ? AppShimmer(child: content) : content;
    },
  );
}
