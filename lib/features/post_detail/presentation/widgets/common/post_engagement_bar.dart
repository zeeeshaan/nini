import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/localization/strings/saved_posts_strings.dart';
import 'package:nini/features/home/presentation/widgets/common/home_metric.dart';
import 'package:nini/features/home/presentation/widgets/common/home_engagement_layout.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class PostEngagementBar extends StatelessWidget {
  const PostEngagementBar({
    super.key,
    this.onCommentsPressed,
    this.post,
    this.seller,
    this.onSharePressed,
    this.onCartPressed,
    this.cartCount = '0',
    this.isInCart = false,
    this.rating,
    this.showSampleMetrics = true,
  });

  final VoidCallback? onCommentsPressed;
  final PostItem? post;
  final PostSeller? seller;
  final VoidCallback? onSharePressed;
  final VoidCallback? onCartPressed;
  final String cartCount;
  final bool isInCart;
  final String? rating;
  final bool showSampleMetrics;

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PostDetailCubit, PostDetailState>(
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
            state.isBookmarked ? AppIcons.bookmarkFilled : AppIcons.bookmark,
            size: 22,
          ),
          selected: state.isBookmarked,
          count: state.isBookmarked ? '1' : '0',
          onTap: () async {
            final detail = context.read<PostDetailCubit>();
            final success = await detail.toggleBookmark(
              post: post,
              seller: seller,
            );
            if (!success && context.mounted) {
              AppToast.show(
                context,
                message: SavedPostsStrings.saveFailed,
                type: AppToastType.error,
              );
            } else if (success &&
                context.mounted &&
                detail.state.isBookmarked) {
              AppToast.success(context, SavedPostsStrings.saved);
            }
          },
        ),
        HomeMetric(
          label: AppStrings.comments,
          icon: const AppIcon(
            AppIcons.postComment,
            size: HomeEngagementLayout.actionIconSize,
          ),
          count: showSampleMetrics ? '886' : '0',
          onTap: onCommentsPressed,
        ),
        HomeMetric(
          label: AppStrings.share,
          icon: const AppIcon(
            AppIcons.postShare,
            size: HomeEngagementLayout.actionIconSize,
          ),
          count: showSampleMetrics ? '350' : '0',
          onTap: onSharePressed,
        ),
        HomeMetric(
          label: state.isLiked ? AppStrings.unlike : AppStrings.like,
          icon: AppIcon(
            state.isLiked ? AppIcons.postLikeFilled : AppIcons.postLike,
            size: HomeEngagementLayout.actionIconSize,
            color: state.isLiked ? AppColors.red : null,
          ),
          selected: state.isLiked,
          count: state.isLiked ? '1' : '0',
          onTap: context.read<PostDetailCubit>().toggleLike,
        ),
        HomeMetric(
          label: isInCart ? CartStrings.remove : AppStrings.addToCart,
          icon: const AppIcon(AppIcons.shoppingBag, size: 22),
          count: cartCount,
          selected: isInCart,
          onTap: onCartPressed,
        ),
      ];
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: HomeEngagementLayout(rating: ratingMetric, actions: actions),
        ),
      );
    },
  );
}
