import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import 'app_shimmer.dart';

class MessageSkeleton extends StatelessWidget {
  const MessageSkeleton({super.key, this.messageCount = 6});

  final int messageCount;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final textScaler = MediaQuery.textScalerOf(context);
      final padding = math.min(
        responsive.horizontalPadding,
        responsive.width / 8,
      );
      final contentWidth = responsive.width - padding * 2;
      final maxBubbleWidth = math.min(contentWidth, 320.0);
      final textScale = textScaler.scale(12) / 12;

      return SizedBox(
        width: responsive.width,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topRight,
          child: SizedBox(
            width: responsive.width,
            child: AppShimmer(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: padding,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(messageCount, (index) {
                    final isMine = index.isEven;
                    final bubbleWidth =
                        (responsive.width * (isMine ? .72 : .60))
                            .clamp(0.0, maxBubbleWidth)
                            .toDouble();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: Align(
                        alignment: isMine
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: SizedBox(
                          width: bubbleWidth,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            textDirection: TextDirection.ltr,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              AppSkeletonBox(
                                width: double.infinity,
                                height: (isMine ? 55 : 42) * textScale,
                                radius: 14,
                              ),
                              const SizedBox(height: 6),
                              AppSkeletonBox(
                                width: 38,
                                height: textScaler.scale(8),
                                radius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
