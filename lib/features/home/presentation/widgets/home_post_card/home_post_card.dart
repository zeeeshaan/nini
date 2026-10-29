import 'package:flutter/material.dart';

import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/presentation/widgets/activity_tracking/post_activity_tracking.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/post_media/post_media_view.dart';

class HomePostCard extends StatelessWidget {
  const HomePostCard({
    super.key,
    required this.post,
    required this.onTap,
    required this.detailsHeight,
  });

  final PostItem post;
  final VoidCallback onTap;
  final double detailsHeight;

  @override
  Widget build(BuildContext context) {
    return PostImpressionTracker(
      post: post,
      child: Material(
        color: Theme.of(context).colorScheme.surface,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: post.media.isNotEmpty
                    ? PostMediaView(media: post.media.first)
                    : Image.asset(
                        post.imageAsset,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.medium,
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Center(
                              child: AppIcon(AppIcons.imageUnavailable),
                            ),
                          );
                        },
                      ),
              ),
              SizedBox(
                height: detailsHeight,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 3,
                    vertical: 3,
                  ),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              post.title,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,

                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            Text(
                              AppStrings.postCategory(post.category),
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              style: const TextStyle(fontSize: 9),
                            ),
                            const SizedBox(height: 4),
                            if (!post.isPublished ||
                                post.details.warehouseStock.isNotEmpty)
                              Text(
                                AppStrings.inStock(post.stockCount),
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(fontSize: 9),
                              ),
                            const Spacer(),
                            if (post.originalPrice.isNotEmpty)
                              Text(
                                AppStrings.persianDigits(post.originalPrice),
                                textDirection: TextDirection.rtl,
                                style: const TextStyle(
                                  fontSize: 10,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            if (post.price.isNotEmpty)
                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        AppStrings.persianDigits(post.price),
                                        textDirection: TextDirection.rtl,
                                        style: const TextStyle(
                                          fontSize: 14,

                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  const Text(
                                    AppStrings.from,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(fontSize: 8, height: 1.3),
                                  ),
                                ],
                              ),
                          ],
                        ),
                      ),
                      if (!post.isPublished || post.originalPrice.isNotEmpty)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppIcon(AppIcons.tag, size: 10),
                              Text(
                                post.isPublished
                                    ? AppStrings.persianDigits(
                                        post.details.discount,
                                      )
                                    : '۵',
                                textDirection: TextDirection.rtl,
                                style: TextStyle(fontSize: 7),
                              ),
                            ],
                          ),
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
