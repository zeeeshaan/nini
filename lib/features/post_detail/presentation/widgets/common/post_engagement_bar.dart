import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/localization/strings/saved_posts_strings.dart';
import 'package:hywork/features/home/presentation/widgets/common/home_metric.dart';
import 'package:hywork/features/home/presentation/widgets/common/home_engagement_layout.dart';
import 'package:hywork/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

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
        previous.likeCount != current.likeCount ||
        previous.commentCount != current.commentCount ||
        previous.isBookmarked != current.isBookmarked,
    builder: (context, state) {
      final displayedRating = rating ?? (showSampleMetrics ? '4.5' : '');
      final ratingMetric = HomeMetric(
        label: displayedRating.isEmpty
            ? PostDetailStrings.postUnrated
            : PostDetailStrings.postRating(displayedRating),
        count: displayedRating,
        icon: const AppIcon(AppIcons.star, size: 26),
      );
      final actions = [
        HomeMetric(
          label: state.isBookmarked
              ? PostDetailStrings.removeBookmark
              : PostDetailStrings.bookmark,
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
          label: PostDetailStrings.comments,
          icon: const AppIcon(
            AppIcons.postComment,
            size: HomeEngagementLayout.actionIconSize,
          ),
          count:
              state.commentCount?.toString() ??
              (post?.metadata['backend'] == true
                  ? ''
                  : (showSampleMetrics ? '886' : '0')),
          onTap: onCommentsPressed,
        ),
        HomeMetric(
          label: PostDetailStrings.share,
          icon: const AppIcon(
            AppIcons.postShare,
            size: HomeEngagementLayout.actionIconSize,
          ),
          count: showSampleMetrics ? '350' : '0',
          onTap: onSharePressed,
        ),
        HomeMetric(
          label: state.isLiked
              ? PostDetailStrings.unlike
              : PostDetailStrings.like,
          icon: AppIcon(
            state.isLiked ? AppIcons.postLikeFilled : AppIcons.postLike,
            size: HomeEngagementLayout.actionIconSize,
            color: state.isLiked ? AppColors.red : null,
          ),
          selected: state.isLiked,
          count:
              state.likeCount?.toString() ??
              (post?.metadata['backend'] == true
                  ? ''
                  : (state.isLiked ? '1' : '0')),
          onTap: () async {
            final success = await context.read<PostDetailCubit>().toggleLike();
            if (!success && context.mounted) {
              AppToast.error(
                context,
                PostDetailStrings.likeFailed,
              );
            }
          },
        ),
        HomeMetric(
          label: isInCart
              ? PostDetailStrings.removeFromCart
              : PostDetailStrings.addToCart,
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
