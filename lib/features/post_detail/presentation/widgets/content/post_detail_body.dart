import 'package:nini/shared/models/post/post_seller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/home/presentation/widgets/common/home_badge.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_author_header.dart';
import 'package:nini/features/post_detail/presentation/widgets/content/post_content.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_engagement_bar.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_features_table.dart';
import 'package:nini/features/post_detail/presentation/widgets/post_image_carousel/post_image_carousel.dart';
import 'package:nini/features/posts/presentation/widgets/common/published_post_content.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class PostDetailBody extends StatefulWidget {
  const PostDetailBody({
    super.key,
    required this.post,
    required this.images,
    this.seller,
    this.onSellerPressed,
    this.onMessagePressed,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onMorePressed,
    this.showPurchaseActions = true,
  });

  final PostItem post;
  final PostSeller? seller;
  final VoidCallback? onSellerPressed;
  final VoidCallback? onMessagePressed;
  final List<String> images;
  final VoidCallback? onCommentsPressed, onSharePressed, onMorePressed;
  final bool showPurchaseActions;

  @override
  State<PostDetailBody> createState() => _PostDetailBodyState();
}

class _PostDetailBodyState extends State<PostDetailBody> {
  void _toggleCart() {
    if (!widget.showPurchaseActions) return;
    final cart = context.read<CartCubit?>();
    final existing = cart?.state.items
        .where((item) => item.id == widget.post.id)
        .firstOrNull;
    final item = existing ?? postCartItem(widget.post, seller: widget.seller);
    if (cart == null || item == null) return;
    final quantity = context.read<PostDetailCubit>().state.quantity;
    if (existing == null && !item.accepts(quantity)) return;
    if (!cart.toggleItem(item.withQuantity(quantity))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cart.state.storageError
                ? AppStrings.cartStorageError
                : AppStrings.cartStockExceeded,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
      );
      return;
    }
    AppToast.success(
      context,
      existing == null ? AppStrings.cartAdded : AppStrings.cartRemoved,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final seller = widget.seller;
    final images = widget.images;
    final showPurchaseActions = widget.showPurchaseActions;
    final quantity = context.select(
      (PostDetailCubit cubit) => cubit.state.quantity,
    );
    final cart = context.watch<CartCubit?>();
    final cartItem = cart?.state.items
        .where((item) => item.id == post.id)
        .firstOrNull;
    final itemToAdd = postCartItem(post, seller: seller);
    final canToggle =
        showPurchaseActions &&
        cart != null &&
        !cart.state.loading &&
        (cartItem != null ||
            (itemToAdd != null && itemToAdd.accepts(quantity)));
    final savedRating = double.tryParse(
      AppStrings.persianDigits(post.metadata['rating'] ?? ''),
    );
    final rating =
        savedRating != null &&
            savedRating.isFinite &&
            savedRating >= 0 &&
            savedRating <= 5
        ? savedRating.toStringAsFixed(1).replaceFirst(RegExp(r'\.0$'), '')
        : null;
    final hasPostContent =
        seller != null || post.isPublished || post.caption.isNotEmpty;
    final features = post.isService && post.features.isEmpty
        ? <(String, String)>[
            (AppStrings.serviceType, AppStrings.postCategory(post.category)),
            (
              AppStrings.serviceUnit,
              (post.details.unit ?? PostUnit.session).label,
            ),
            (
              AppStrings.serviceMinimumOrder,
              '1 ${(post.details.unit ?? PostUnit.session).label}',
            ),
            if (post.details.address?.address.isNotEmpty == true)
              (AppStrings.serviceArea, post.details.address!.address),
          ]
        : post.features;
    return SafeArea(
      top: false,
      bottom: false,
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
                padding: EdgeInsets.only(
                  bottom: MediaQuery.paddingOf(context).bottom,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StaggeredEntrance(
                      child: PostAuthorHeader(
                        onMorePressed: widget.onMorePressed,
                        onProfilePressed: widget.onSellerPressed,
                        onMessagePressed: widget.onMessagePressed,
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
                        avatarAsset: seller?.avatarAsset ?? '',
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
                        mediaFit: BoxFit.cover,
                      ),
                    ),

                    StaggeredEntrance(
                      index: 2,
                      child: PostEngagementBar(
                        post: post,
                        seller: seller,
                        onCommentsPressed: widget.onCommentsPressed,
                        showSampleMetrics: !hasPostContent,
                        rating: rating,
                        cartCount: cartItem == null
                            ? '0'
                            : cartQuantity(cartItem.quantity),
                        isInCart: cartItem != null,
                        onCartPressed: canToggle ? _toggleCart : null,
                        onSharePressed: widget.onSharePressed,
                      ),
                    ),

                    StaggeredEntrance(
                      index: 4,
                      child: hasPostContent
                          ? PublishedPostContent(
                              key: ObjectKey(post),
                              post: post,
                              serviceLayout: post.isService,
                            )
                          : const PostContent(),
                    ),

                    if (!post.isService)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: HomeBadge(
                            label: post.stockCount > 0
                                ? AppStrings.inStock(post.stockCount)
                                : AppStrings.stockUnavailable,
                            background: AppColors.stockBadgeBackground,
                            foreground: AppColors.notificationBadge,
                          ),
                        ),
                      ),

                    if (!hasPostContent || features.isNotEmpty)
                      StaggeredEntrance(
                        index: 5,
                        child: PostFeaturesTable(
                          features: hasPostContent
                              ? features
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
    );
  }
}
