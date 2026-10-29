import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/post_analytics/presentation/pages/post_analytics_screen.dart';
import 'package:nini/features/post_analytics/presentation/widgets/activity_tracking/post_activity_tracking.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/author_header/post_author_header.dart';
import 'package:nini/features/post_detail/presentation/widgets/content/post_content.dart';
import 'package:nini/features/post_detail/presentation/widgets/engagement_bar/post_engagement_bar.dart';
import 'package:nini/features/post_detail/presentation/widgets/feature_table/post_features_table.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/features/posts/presentation/widgets/published_post_content.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.galleryImages,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onMorePressed,
  });

  final PostItem post;
  final List<String>? galleryImages;

  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onMorePressed;

  @override
  Widget build(BuildContext context) {
    final images = galleryImages != null && galleryImages!.isNotEmpty
        ? galleryImages!
        : <String>[post.imageAsset];

    return BlocProvider(
      create: (_) => PostDetailCubit(),
      child: PostDetailActivityTracker(
        post: post,
        child: ScreenEntrance(
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              toolbarHeight: 44,
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PostAnalyticsScreen(post: post),
                    ),
                  ),
                  icon: const AppIcon(AppIcons.analytics, size: 17),
                  label: const Text(
                    AppStrings.viewAnalytics,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              automaticallyImplyLeading: false,
              leadingWidth: 48,
              leading: StaggeredEntrance(
                distance: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(AppIcons.back, size: 18),
                  tooltip: AppStrings.back,
                ),
              ),
            ),

            body: SafeArea(
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
                                name: post.isPublished
                                    ? AppStrings.sellerName
                                    : AppStrings.authorName,
                                location: post.isPublished
                                    ? (post.details.address?.address ?? '')
                                    : AppStrings.authorLocation,
                                avatarAsset: post.isPublished
                                    ? 'assets/Mask group.png'
                                    : 'assets/images/profile_avatar.png',
                              ),
                            ),

                            StaggeredEntrance(
                              index: 1,
                              child: PostImageCarousel(
                                images: images,
                                media: post.media,
                              ),
                            ),

                            StaggeredEntrance(
                              index: 2,
                              child: PostEngagementBar(
                                onCommentsPressed: onCommentsPressed,
                                showSampleMetrics: !post.isPublished,
                                onSharePressed: onSharePressed,
                              ),
                            ),

                            StaggeredEntrance(
                              index: 3,
                              child: post.isPublished
                                  ? PublishedPostContent(post: post)
                                  : const PostContent(),
                            ),

                            if (!post.isPublished || post.features.isNotEmpty)
                              StaggeredEntrance(
                                index: 4,
                                child: PostFeaturesTable(
                                  features: post.isPublished
                                      ? post.features
                                      : AppStrings.features,
                                ),
                              ),

                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
