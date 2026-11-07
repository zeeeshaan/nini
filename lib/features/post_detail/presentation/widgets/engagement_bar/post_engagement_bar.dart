import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/home/presentation/widgets/home_metric/home_metric.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostEngagementBar extends StatelessWidget {
  const PostEngagementBar({
    super.key,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onCartPressed,
    this.cartCount = '0',
    this.rating,
    this.showSampleMetrics = true,
  });

  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCartPressed;
  final String cartCount;
  final String? rating;
  final bool showSampleMetrics;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostDetailCubit, PostDetailState>(
        buildWhen: (previous, current) =>
            previous.isLiked != current.isLiked ||
            previous.isBookmarked != current.isBookmarked,
        builder: (context, state) {
          final displayedRating = rating ?? (showSampleMetrics ? '4.5' : '');
          final ratingMetric = HomeMetric(
            label: displayedRating.isEmpty
                ? AppStrings.postUnrated
                : AppStrings.postRating(displayedRating),
            count: displayedRating,
            icon: const AppIcon(AppIcons.star, size: 26),
          );
          final actions = [
            HomeMetric(
              label: state.isBookmarked
                  ? AppStrings.removeBookmark
                  : AppStrings.bookmark,
              icon: AppIcon(
                state.isBookmarked
                    ? AppIcons.bookmarkFilled
                    : AppIcons.bookmark,
                size: 22,
              ),
              selected: state.isBookmarked,
              count: showSampleMetrics
                  ? '782'
                  : state.isBookmarked
                  ? '1'
                  : '0',
              onTap: context.read<PostDetailCubit>().toggleBookmark,
            ),
            HomeMetric(
              label: AppStrings.comments,
              icon: const AppIcon(AppIcons.chat, size: 22),
              count: showSampleMetrics ? '886' : '0',
              onTap: onCommentsPressed,
            ),
            HomeMetric(
              label: AppStrings.share,
              icon: const AppIcon(AppIcons.send, size: 22),
              count: showSampleMetrics ? '350' : '0',
              onTap: onSharePressed,
            ),
            HomeMetric(
              label: state.isLiked ? AppStrings.unlike : AppStrings.like,
              icon: AppIcon(
                state.isLiked ? AppIcons.heartFilled : AppIcons.heart,
                size: 22,
              ),
              selected: state.isLiked,
              count: showSampleMetrics
                  ? '45K'
                  : state.isLiked
                  ? '1'
                  : '0',
              onTap: context.read<PostDetailCubit>().toggleLike,
            ),
            HomeMetric(
              label: AppStrings.cart,
              icon: const AppIcon(AppIcons.shoppingBag, size: 22),
              count: showSampleMetrics ? '786' : cartCount,
              onTap: onCartPressed,
            ),
          ];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: MediaQuery.textScalerOf(context).scale(10) > 13
                  ? Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 8,
                      children: [ratingMetric, ...actions],
                    )
                  : Row(
                      children: [
                        ratingMetric,
                        const SizedBox(width: 12),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (
                                    var index = 0;
                                    index < actions.length;
                                    index++
                                  ) ...[
                                    if (index > 0) const SizedBox(width: 6),
                                    actions[index],
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          );
        },
      );
}
