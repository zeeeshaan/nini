import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';

import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/features/post_analytics/presentation/widgets/metrics/post_activity_tracking.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/features/posts/presentation/widgets/media/post_media_view.dart';

class SearchResultCard extends StatelessWidget {
  const SearchResultCard({
    super.key,
    required this.post,
    this.onTap,
    this.contentScale = 1,
  });

  final PostItem post;
  final VoidCallback? onTap;
  final double contentScale;

  String _price(String value) => AppStrings.persianDigits(
    value.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]}٬',
    ),
  );

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurface
        .withValues(alpha: .55);
    return PostImpressionTracker(
      post: post,
      source: 'search',
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    post.media.isEmpty
                        ? Image.asset(post.imageAsset, fit: BoxFit.cover)
                        : PostMediaView(media: post.media.first),
                    if (post.details.discount.isNotEmpty)
                      Positioned(
                        top: 8,
                        right: 7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: AppColors.notificationBadge,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${AppStrings.persianDigits(post.details.discount)}%',
                            style: AppTextStyles.metadataBold.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 3, 4, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        SearchStrings.display(post.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.profileCardText
                            .merge(AppTextStyles.postCardHeading)
                            .copyWith(
                              fontSize:
                                  AppTextStyles.postCardHeading.fontSize! *
                                  contentScale,
                            ),
                      ),
                      if (post.details.tags.contains(AppStrings.preOrder))
                        Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.onSurface,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              AppStrings.preOrder,
                              style: AppTextStyles.badgeSmall.copyWith(
                                color: Theme.of(context).colorScheme.surface,
                              ),
                            ),
                          ),
                        ),
                      const Spacer(),
                      if (post.originalPrice.isNotEmpty)
                        Text(
                          _price(post.originalPrice),
                          style: AppTextStyles.micro.copyWith(
                            color: secondary,
                            decoration: TextDecoration.lineThrough,
                          ),
                          textAlign: TextAlign.right,
                        ),
                      Text(
                        '${_price(post.price)} ${SearchStrings.currency}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallPrint,
                        textAlign: TextAlign.right,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
