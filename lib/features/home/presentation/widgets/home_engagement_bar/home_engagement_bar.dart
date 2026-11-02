import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import 'package:nini/features/home/presentation/widgets/home_metric/home_metric.dart';

class HomeEngagementBar extends StatelessWidget {
  const HomeEngagementBar({
    super.key,
    required this.isLiked,
    required this.isBookmarked,
    required this.onLike,
    required this.onBookmark,
    this.onAddToCart,
  });

  final bool isLiked;
  final bool isBookmarked;
  final VoidCallback onLike;
  final VoidCallback onBookmark;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) {
    const rating = HomeMetric(
      label: AppStrings.rating,
      count: '4.5',
      icon: AppIcon(AppIcons.star, size: 24),
    );
    final actions = [
      HomeMetric(
        label: isBookmarked ? AppStrings.removeBookmark : AppStrings.bookmark,
        count: isBookmarked ? '783' : '782',
        selected: isBookmarked,
        onTap: onBookmark,
        icon: AppIcon(
          isBookmarked ? AppIcons.bookmarkFilled : AppIcons.bookmark,
          size: 22,
        ),
      ),
      const HomeMetric(
        label: AppStrings.comments,
        count: '886',
        icon: AppIcon(AppIcons.chat, size: 22),
      ),
      const HomeMetric(
        label: AppStrings.share,
        count: '350',
        icon: AppIcon(AppIcons.send, size: 22),
      ),
      HomeMetric(
        label: isLiked ? AppStrings.unlike : AppStrings.like,
        count: isLiked ? '۴۵ هزار' : '44,999',
        selected: isLiked,
        onTap: onLike,
        icon: AppIcon(
          isLiked ? AppIcons.heartFilled : AppIcons.heart,
          size: 22,
        ),
      ),
      HomeMetric(
        onTap: onAddToCart,
        label: AppStrings.cart,
        count: '786',
        icon: const AppIcon(AppIcons.shoppingBag, size: 22),
      ),
    ];

    Widget content;
    if (MediaQuery.textScalerOf(context).scale(10) > 13) {
      content = Wrap(
        alignment: WrapAlignment.spaceBetween,
        spacing: 8,
        children: [rating, ...actions],
      );
    } else {
      content = Row(
        children: [
          rating,
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
                    for (var index = 0; index < actions.length; index++) ...[
                      if (index > 0) const SizedBox(width: 6),
                      actions[index],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: content,
    );
  }
}
