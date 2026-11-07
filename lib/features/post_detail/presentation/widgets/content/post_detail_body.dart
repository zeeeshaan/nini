import 'package:nini/shared/models/post/post_seller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
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
  final _purchaseKey = GlobalKey();

  void _revealPurchase() {
    final target = _purchaseKey.currentContext;
    if (target == null) return;
    Scrollable.ensureVisible(
      target,
      alignment: 1,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final seller = widget.seller;
    final images = widget.images;
    final showPurchaseActions = widget.showPurchaseActions;
    final cartItem = context
        .watch<CartCubit?>()
        ?.state
        .items
        .where((item) => item.id == post.id)
        .firstOrNull;
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
                        onCommentsPressed: widget.onCommentsPressed,
                        showSampleMetrics: !hasPostContent,
                        rating: rating,
                        cartCount: cartItem == null
                            ? '0'
                            : cartQuantity(cartItem.quantity),
                        onCartPressed: showPurchaseActions
                            ? _revealPurchase
                            : null,
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
                    if (showPurchaseActions)
                      PostDetailBottomBar(
                        key: _purchaseKey,
                        post: post,
                        seller: seller,
                      )
                    else if (!showPurchaseActions && post.price.isNotEmpty)
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
