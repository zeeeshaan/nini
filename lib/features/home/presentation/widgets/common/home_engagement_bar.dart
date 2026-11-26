import 'package:flutter/material.dart';

import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

import 'package:hywork/features/home/presentation/widgets/common/home_metric.dart';

import 'home_engagement_layout.dart';

class HomeEngagementBar extends StatelessWidget {
  const HomeEngagementBar({
    super.key,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLike,
    required this.onBookmark,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onAddToCart,
    this.cartCount = '0',
    this.isInCart = false,
    this.showSampleMetrics = true,
    this.likeCount,
    this.backendLikes = false,
    this.commentCount,
  });

  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onAddToCart;
  final String cartCount;
  final bool isInCart;
  final bool showSampleMetrics;
  final int? likeCount;
  final bool backendLikes;
  final int? commentCount;

  @override
  Widget build(BuildContext context) {
    final bookmarkCount = isBookmarked ? '1' : '0';
    final displayedLikes =
        likeCount?.toString() ?? (backendLikes ? '' : (isLiked ? '1' : '0'));
    final rating = HomeMetric(
      label: HomeStrings.rating,
      count: showSampleMetrics ? '4.5' : '',
      icon: const AppIcon(AppIcons.star, size: 24),
    );
    final actions = [
      HomeMetric(
        label: isBookmarked
            ? HomeStrings.removeBookmark
            : HomeStrings.bookmark,
        count: bookmarkCount,
        selected: isBookmarked,
        onTap: onBookmark,
        icon: AppIcon(
          isBookmarked ? AppIcons.bookmarkFilled : AppIcons.bookmark,
          size: 22,
        ),
      ),
      HomeMetric(
        label: HomeStrings.comments,
        count:
            commentCount?.toString() ??
            (backendLikes ? '' : (showSampleMetrics ? '886' : '0')),
        onTap: onCommentsPressed,
        icon: const AppIcon(
          AppIcons.postComment,
          size: HomeEngagementLayout.actionIconSize,
        ),
      ),
      HomeMetric(
        label: HomeStrings.share,
        count: showSampleMetrics ? '350' : '0',
        onTap: onSharePressed,
        icon: const AppIcon(
          AppIcons.postShare,
          size: HomeEngagementLayout.actionIconSize,
        ),
      ),
      HomeMetric(
        label: isLiked ? HomeStrings.unlike : HomeStrings.like,
        count: displayedLikes,
        selected: isLiked,
        onTap: onLike,
        icon: AppIcon(
          isLiked ? AppIcons.postLikeFilled : AppIcons.postLike,
          size: HomeEngagementLayout.actionIconSize,
          color: isLiked ? AppColors.red : null,
        ),
      ),
      HomeMetric(
        onTap: onAddToCart,
        label: isInCart ? HomeStrings.removeFromCart : HomeStrings.addToCart,
        count: cartCount,
        selected: isInCart,
        icon: const AppIcon(AppIcons.shoppingBag, size: 22),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: HomeEngagementLayout(rating: rating, actions: actions),
    );
  }
}
