import 'package:nini/shared/models/post/post_seller.dart';
import 'package:flutter/material.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/post_detail/presentation/widgets/author_header/post_author_header.dart';
import 'package:nini/features/post_detail/presentation/widgets/bottom_bar/post_detail_bottom_bar.dart';
import 'package:nini/features/post_detail/presentation/widgets/content/post_content.dart';
import 'package:nini/features/post_detail/presentation/widgets/engagement_bar/post_engagement_bar.dart';
import 'package:nini/features/post_detail/presentation/widgets/feature_table/post_features_table.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/features/post_detail/presentation/widgets/pricing/post_pricing.dart';
import 'package:nini/features/posts/presentation/widgets/published_post_content.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PostDetailBody extends StatelessWidget {
  const PostDetailBody({
    super.key,
    required this.post,
    required this.images,
    this.seller,
    this.onSellerPressed,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onMorePressed,
    this.showPurchaseActions = true,
  });

  final PostItem post;
  final PostSeller? seller;
  final VoidCallback? onSellerPressed;
  final List<String> images;
  final VoidCallback? onCommentsPressed, onSharePressed, onMorePressed;
  final bool showPurchaseActions;

  @override
  Widget build(BuildContext context) {
    final hasPostContent =
        seller != null || post.isPublished || post.caption.isNotEmpty;
    return SafeArea(
      top: false,
      child: AppResponsiveBuilder(
        builder: (context, responsive) {
          final maxWidth = responsive.adaptive<double>(
            compact: 600,
            medium: 640,
            expanded: 720,
          );

          return Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaggeredEntrance(
                      child: PostAuthorHeader(
                        onMorePressed: onMorePressed,
                        onProfilePressed: onSellerPressed,
                        name:
                            seller?.name ??
                            (hasPostContent
                                ? AppStrings.sellerName
                                : AppStrings.authorName),
                        location:
                            seller?.location ??
                            (hasPostContent
                                ? (post.details.address?.address ?? '')
                                : AppStrings.authorLocation),
                        avatarAsset:
                            seller?.avatarAsset ??
                            (hasPostContent
                                ? 'assets/Mask group.png'
                                : 'assets/images/profile_avatar.png'),
                      ),
                    ),

                    StaggeredEntrance(
                      index: 1,
                      child: PostImageCarousel(
                        key: ValueKey(
                          post.media.map((item) => item.path).join('|'),
                        ),
                        images: images,
                        media: post.media,
                      ),
                    ),

                    StaggeredEntrance(
                      index: 2,
                      child: PostEngagementBar(
                        onCommentsPressed: onCommentsPressed,
                        showSampleMetrics: !hasPostContent,
                        onSharePressed: onSharePressed,
                      ),
                    ),

                    StaggeredEntrance(
                      index: 4,
                      child: hasPostContent
                          ? PublishedPostContent(
                              key: ObjectKey(post),
                              post: post,
                            )
                          : const PostContent(),
                    ),

                    if (!hasPostContent || post.features.isNotEmpty)
                      StaggeredEntrance(
                        index: 5,
                        child: PostFeaturesTable(
                          features: hasPostContent
                              ? post.features
                              : AppStrings.features,
                        ),
                      ),

                    const SizedBox(height: 40),
                    if (showPurchaseActions)
                      PostDetailBottomBar(post: post, seller: seller)
                    else if (post.price.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 22),
                        child: PostPricing(post: post),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
