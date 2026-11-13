import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/features/home/presentation/widgets/common/home_metric.dart';

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

  @override
  Widget build(BuildContext context) {
    final bookmarkCount = isBookmarked ? '1' : '0';
    final likeCount = isLiked ? '1' : '0';
    final rating = HomeMetric(
      label: AppStrings.rating,
      count: showSampleMetrics ? '4.5' : '',
      icon: const AppIcon(AppIcons.star, size: 24),
    );
    final actions = [
      HomeMetric(
        label: isBookmarked ? AppStrings.removeBookmark : AppStrings.bookmark,
        count: bookmarkCount,
        selected: isBookmarked,
        onTap: onBookmark,
        icon: AppIcon(
          isBookmarked ? AppIcons.bookmarkFilled : AppIcons.bookmark,
          size: 22,
        ),
      ),
      HomeMetric(
        label: AppStrings.comments,
        count: showSampleMetrics ? '886' : '0',
        onTap: onCommentsPressed,
        icon: const AppIcon(
          AppIcons.postComment,
          size: HomeEngagementLayout.actionIconSize,
        ),
      ),
      HomeMetric(
        label: AppStrings.share,
        count: showSampleMetrics ? '350' : '0',
        onTap: onSharePressed,
        icon: const AppIcon(
          AppIcons.postShare,
          size: HomeEngagementLayout.actionIconSize,
        ),
      ),
      HomeMetric(
        label: isLiked ? AppStrings.unlike : AppStrings.like,
        count: likeCount,
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
        label: isInCart ? CartStrings.remove : AppStrings.addToCart,
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
