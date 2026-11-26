import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class ListTileSkeleton extends StatelessWidget {
  const ListTileSkeleton({
    super.key,
    this.showAvatar = true,
    this.animated = true,
  });

  final bool showAvatar;
  final bool animated;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final textScaler = MediaQuery.textScalerOf(context);
      final padding = math.min(
        responsive.horizontalPadding,
        responsive.width / 8,
      );
      final contentWidth = responsive.width - padding * 2;
      final avatarSize = math.min(46.0, contentWidth / 4);
      final gap = math.min(14.0, contentWidth / 8);

      return SizedBox(
        width: responsive.width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topRight,
          child: SizedBox(
            width: responsive.width,
            child: AppShimmer.when(
              enabled: animated,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 12,
                ),
                child: Row(
                  textDirection: TextDirection.ltr,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        textDirection: TextDirection.ltr,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          AppSkeletonBox(
                            width: 150,
                            height: textScaler.scale(12),
                          ),
                          const SizedBox(height: 10),
                          AppSkeletonBox(
                            width: 210,
                            height: textScaler.scale(10),
                          ),
                        ],
                      ),
                    ),
                    if (showAvatar) ...[
                      SizedBox(width: gap),
                      AppSkeletonBox(
                        width: avatarSize,
                        height: avatarSize,
                        isCircle: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
