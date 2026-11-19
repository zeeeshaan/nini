import 'package:flutter/material.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_author_header.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'app_shimmer.dart';

/// Keeps card data visible while the remaining post details are fetched.
class DetailsSkeleton extends StatelessWidget {
  const DetailsSkeleton({super.key, required this.post});

  final PostItem post;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) {
      final seller = SearchCatalog.sellerFor(post);
      final scale = MediaQuery.textScalerOf(context);
      return Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: responsive.adaptive<double>(
              compact: 600,
              medium: 640,
              expanded: 720,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PostAuthorHeader(
                  name: seller?.name ?? '',
                  location: seller?.location ?? '',
                  avatarAsset: seller?.avatarAsset ?? '',
                ),
                if (post.media.isNotEmpty || post.imageAsset.isNotEmpty)
                  PostImageCarousel(
                    media: post.media,
                    images: [post.imageAsset],
                    mediaFit: BoxFit.cover,
                  )
                else
                  const AppShimmer(
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: AppSkeletonBox(height: double.infinity, radius: 0),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        post.title,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (post.price.isNotEmpty)
                        Text(post.price, textAlign: TextAlign.right),
                      const SizedBox(height: 16),
                      AppShimmer(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            AppSkeletonBox(
                              height: scale.scale(12),
                              width: double.infinity,
                              radius: 3,
                            ),
                            const SizedBox(height: 8),
                            AppSkeletonBox(
                              height: scale.scale(12),
                              width: 180,
                              radius: 3,
                            ),
                            const SizedBox(height: 24),
                            AppSkeletonBox(
                              height: scale.scale(12),
                              width: 110,
                              radius: 3,
                            ),
                            const SizedBox(height: 12),
                            AppSkeletonBox(
                              height: scale.scale(12),
                              width: double.infinity,
                              radius: 3,
                            ),
                            const SizedBox(height: 10),
                            AppSkeletonBox(
                              height: scale.scale(12),
                              width: double.infinity,
                              radius: 3,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
