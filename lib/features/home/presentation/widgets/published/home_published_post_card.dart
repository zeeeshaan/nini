import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/core/localization/strings/saved_posts_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/presentation/helpers/cart_format.dart';
import 'package:hywork/features/home/data/home_post_data.dart';
import 'package:hywork/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:hywork/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:hywork/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:hywork/features/posts/presentation/widgets/interactions/comments_sheet.dart';
import 'package:hywork/features/posts/presentation/widgets/interactions/share_sheet.dart';
import 'package:hywork/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:hywork/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:hywork/features/search/data/search_catalog.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';

import 'home_post_media_slider.dart';
import '../common/home_badge.dart';
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

  String? _discountLabel() {
    double? amount(String value) {
      final normalized = AppStrings.latinDigits(value)
          .replaceAll(RegExp(r'[,٬\s]'), '')
          .replaceAll('٫', '.')
          .trim();

      return double.tryParse(normalized);
    }

    final original = amount(post.originalPrice);
    final current = amount(post.price);

    if (original == null ||
        current == null ||
        original <= 0 ||
        current < 0 ||
        current >= original) {
      return null;
    }

    final percentage = (original - current) * 100 / original;

    final value = percentage.roundToDouble() == percentage
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(1);

    return '%${AppStrings.persianDigits(value)}';
  }

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
        if (context.mounted) {
          AppToast.warning(context, HomeStrings.loadDetailsFailed);
        }
        return;
      }
    }

    if (!context.mounted) return;
    if (cart == null || item == null) return;

    if (cart.toggleItem(item.withQuantity(100))) {
      AppToast.success(
        context,
        existing == null ? HomeStrings.cartAdded : HomeStrings.cartRemoved,
      );
    } else {
      AppToast.show(
        context,
        message: cart.state.storageError
            ? HomeStrings.cartStorageError
            : HomeStrings.cartStockExceeded,
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

    final discountLabel = _discountLabel();

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

          // Discount chip over the existing post image.
          Stack(
            children: [
              HomePostMediaSlider(
                post: post,
                active: active,
                onTap: () => _openPost(context),
              ),
              if (discountLabel != null)
                Positioned(
                  top: 12,
                  right: 12,
                  child: IgnorePointer(
                    child: HomeBadge(
                      label: discountLabel,
                      background: AppColors.notificationBadge,
                      foreground: Colors.white,
                    ),
                  ),
                ),
            ],
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
                  HomeStrings.postCategory(post.category),
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
