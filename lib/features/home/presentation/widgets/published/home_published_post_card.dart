import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/comments_sheet.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/share_sheet.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/core/localization/strings/saved_posts_strings.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';

import 'home_post_media_slider.dart';
import '../common/home_post_pricing.dart';
import '../common/home_engagement_bar.dart';
import '../common/home_seller_header.dart';

class HomePublishedPostCard extends StatelessWidget {
  const HomePublishedPostCard({
    super.key,
    required this.post,
    this.active = true,
    this.onProfilePressed,
  });
  final PostItem post;
  final bool active;
  final VoidCallback? onProfilePressed;

  void _openPost(BuildContext context) => openPublishedHomePost(
    context,
    post,
    onOwnProfilePressed: onProfilePressed,
  );

  Future<void> _toggleCart(BuildContext context) async {
    final cart = context.read<CartCubit?>();
    final seller =
        SearchCatalog.sellerFor(post) ??
        context.read<UserProfileCubit?>()?.seller ??
        localPostSeller;
    final existing = cart?.state.items
        .where((item) => item.id == post.id)
        .firstOrNull;
    var item = existing ?? postCartItem(post, seller: seller);
    if (item == null && post.metadata['backend'] == true && cart != null) {
      try {
        final detail = await context.read<ApiPostsRepository>().loadDetail(
          post.id,
        );
        item = postCartItem(
          detail,
          seller: SearchCatalog.sellerFor(detail) ?? seller,
        );
      } catch (_) {
        if (context.mounted)
          AppToast.warning(context, 'Could not load post details.');
        return;
      }
    }
    if (!context.mounted) return;
    if (cart == null || item == null) return;
    if (cart.toggleItem(item.withQuantity(100))) {
      AppToast.success(
        context,
        existing == null ? AppStrings.cartAdded : AppStrings.cartRemoved,
      );
    } else {
      AppToast.show(
        context,
        message: cart.state.storageError
            ? AppStrings.cartStorageError
            : AppStrings.cartStockExceeded,
        type: AppToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartCubit?>();
    final seller =
        SearchCatalog.sellerFor(post) ??
        context.watch<UserProfileCubit?>()?.seller ??
        localPostSeller;
    final inCart = cart?.state.items
        .where((item) => item.id == post.id)
        .firstOrNull;
    final item = postCartItem(post, seller: seller);
    final canToggle =
        cart != null &&
        !cart.state.loading &&
        (inCart != null ||
            (item != null && item.accepts(100)) ||
            (post.metadata['backend'] == true &&
                post.metadata['inStock'] == true));
    return BlocProvider(
      create: (context) => PostDetailCubit(
        postId: post.id,
        post: post,
        repository: post.metadata['backend'] == true
            ? context.read<ApiPostsRepository?>()
            : null,
        likes: context.read<PostLikesCubit?>(),
        savedPosts: context.read<SavedPostsCubit?>(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          HomeSellerHeader(
            seller: seller,
            onPressed: () => openPublishedHomeSeller(
              context,
              post,
              onOwnProfilePressed: onProfilePressed,
            ),
          ),
          HomePostMediaSlider(
            post: post,
            active: active,
            onTap: () => _openPost(context),
          ),
          BlocBuilder<PostDetailCubit, PostDetailState>(
            buildWhen: (previous, current) =>
                previous.isLiked != current.isLiked ||
                previous.likeCount != current.likeCount ||
                previous.commentCount != current.commentCount ||
                previous.isBookmarked != current.isBookmarked,
            builder: (context, state) => HomeEngagementBar(
              isLiked: state.isLiked,
              likeCount: state.likeCount,
              backendLikes: post.metadata['backend'] == true,
              commentCount: state.commentCount,
              isBookmarked: state.isBookmarked,
              showSampleMetrics: false,
              cartCount: inCart == null ? '0' : cartQuantity(inCart.quantity),
              isInCart: inCart != null,
              onAddToCart: canToggle ? () => _toggleCart(context) : null,
              onLike: () async {
                final success = await context
                    .read<PostDetailCubit>()
                    .toggleLike();
                if (!success && context.mounted) {
                  AppToast.error(
                    context,
                    'Unable to update like. Please try again.',
                  );
                }
              },
              onBookmark: () async {
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
              onCommentsPressed: () => openPostCommentsSheet(
                context,
                postId: post.id,
                backend: post.metadata['backend'] == true,
              ),
              onSharePressed: () => openPostShareSheet(
                context,
                postId: post.id,
                postText: [
                  post.title,
                  post.caption,
                ].where((text) => text.trim().isNotEmpty).join('\n\n'),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                InkWell(
                  onTap: () => _openPost(context),
                  child: Text(
                    post.title,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    softWrap: true,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.homePostTitle,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.postCategory(post.category),
                  textAlign: TextAlign.right,
                  style: AppTextStyles.heading.copyWith(
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .3),
                  ),
                  textDirection: TextDirection.ltr,
                ),
                if (post.price.isNotEmpty || !post.isService) ...[
                  const SizedBox(height: 12),
                  HomePostPricing(post: post),
                ],
              ],
            ),
          ),
          const Divider(height: 1, thickness: .5),
        ],
      ),
    );
  }
}
