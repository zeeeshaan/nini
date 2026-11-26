import 'package:flutter/material.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';

import '../../../domain/public_user_profile.dart';
import '../categories/category_chips.dart';

import 'seller_profile_actions.dart';
import 'seller_post_grid.dart';
import 'seller_profile_header.dart';

class SellerProfileContent extends StatelessWidget {
  const SellerProfileContent({
    super.key,
    required this.profile,
    this.categories,
    this.categoryMessage,
    this.onFollow,
    this.following = false,
    this.posts = const BackendPostsState(),
    this.selectedCategoryId,
    this.onCategorySelected,
    this.onPostTap,
    this.onRetryPosts,
  });

  final PublicUserProfile profile;
  final ProfileCategoryList? categories;
  final String? categoryMessage;
  final VoidCallback? onFollow;
  final bool following;
  final BackendPostsState posts;
  final String? selectedCategoryId;
  final ValueChanged<String?>? onCategorySelected;
  final ValueChanged<PostItem>? onPostTap;
  final VoidCallback? onRetryPosts;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsive.adaptive<double>(
            compact: 600,
            medium: 600,
            expanded: 720,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                16,
              ),
              child: SellerProfileHeader(
                profile: profile,
                postCount: categories?.allCount,
                avatarSize: responsive.adaptive<double>(
                  compact: 104,
                  medium: 124,
                  expanded: 136,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: SellerProfileActions(
                seller: profile.seller,
                isFollowing: profile.isFollowing,
                onFollow: onFollow,
                following: following,
              ),
            ),
            const SizedBox(height: 16),
            if (categories case final publicCategories?)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalPadding,
                ),
                child: ProfileCategoryChips.readOnly(
                  categories: publicCategories,
                  selectedId: selectedCategoryId,
                  onSelect: onCategorySelected,
                ),
              ),
            SellerPostGrid(
              posts: posts.posts,
              onPostTap: onPostTap ?? (_) {},
              emptyMessage: posts.loading
                  ? ProfileScreenStrings.postsLoading
                  : posts.error
                  ? ProfileScreenStrings.postsLoadFailed
                  : categoryMessage ?? ProfileScreenStrings.noSellerPosts,
            ),
            if (posts.error)
              TextButton(
                onPressed: onRetryPosts,
                child: const Text(ProfileScreenStrings.retry),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
