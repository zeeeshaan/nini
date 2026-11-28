// dart format width=100
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

class CartLoading extends StatelessWidget {
  const CartLoading({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: 3,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (_, _) => const _CartLoadingCard(),
      ),
    );
  }
}

class _CartLoadingCard extends StatelessWidget {
  const _CartLoadingCard();

  @override
  Widget build(BuildContext context) => Material(
    color: Theme.of(context).colorScheme.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(color: Theme.of(context).dividerColor),
    ),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final imageSize = math.min(110.0, constraints.maxWidth * .26);
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: SizedBox(
                  height: imageSize,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const AppSkeletonBox(width: 120, height: 12, radius: 3),
                      const SizedBox(height: 6),
                      const AppSkeletonBox(width: 75, height: 9, radius: 3),
                      const Spacer(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Flexible(child: AppSkeletonBox(width: 55, height: 22, radius: 6)),
                          const SizedBox(width: 8),
                          const Flexible(child: AppSkeletonBox(width: 70, height: 14, radius: 3)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 14),
              AppSkeletonBox(width: imageSize, height: imageSize, radius: 8),
            ],
          );
        },
      ),
    ),
  );
}
