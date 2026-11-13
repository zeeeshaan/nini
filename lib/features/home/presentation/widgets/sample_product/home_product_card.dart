import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/widgets/common/home_seller_header.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/home/presentation/cubit/home_card_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/comments_sheet.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/share_sheet.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/core/localization/strings/saved_posts_strings.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/models/post/post_unit.dart';

import 'package:nini/features/home/presentation/widgets/common/home_engagement_bar.dart';
import 'package:nini/features/home/presentation/widgets/sample_product/home_product_details.dart';
import 'package:nini/features/home/presentation/widgets/sample_product/home_product_image.dart';
import 'package:nini/features/home/presentation/widgets/sample_product/home_product_price.dart';

class HomeProductCard extends StatefulWidget {
  const HomeProductCard({
    super.key,
    required this.imageUrl,
    required this.title,
    this.onViewCart,
    this.seller = homeSeller,
  });

  final String imageUrl;
  final String title;
  final PostSeller seller;
  final VoidCallback? onViewCart;

  @override
  State<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends State<HomeProductCard>
    with AutomaticKeepAliveClientMixin {
  late final HomeCardCubit _card;

  @override
  void initState() {
    super.initState();
    _card = HomeCardCubit(
      postId: homeProductPost(
        title: widget.title,
        imageUrl: widget.imageUrl,
      ).id,
      likes: context.read<PostLikesCubit?>(),
      savedPosts: context.read<SavedPostsCubit?>(),
    );
  }

  @override
  bool get wantKeepAlive => true;

  void _toggleCart() {
    final cart = context.read<CartCubit>();
    final wasInCart = cart.state.items.any((item) => item.id == 'home-pixel9');
    final changed = cart.toggleItem(
      CartItem(
        id: 'home-pixel9',
        title: widget.title,
        category: AppStrings.mobile,
        unit: PostUnit.piece,
        unitPrice: 13000,
        discountPerUnit: 1000,
        maxQuantity: 200,
        imageUrl: widget.imageUrl,
        isPreOrder: true,
        seller: widget.seller,
      ),
    );
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          action: changed && !wasInCart && widget.onViewCart != null
              ? SnackBarAction(
                  label: AppStrings.viewCart,
                  onPressed: widget.onViewCart!,
                )
              : null,
          content: Text(
            changed
                ? (wasInCart ? AppStrings.cartRemoved : AppStrings.cartAdded)
                : cart.state.storageError
                ? AppStrings.cartStorageError
                : AppStrings.cartStockExceeded,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
        ),
      );
  }

  @override
  void dispose() {
    _card.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return BlocBuilder<HomeCardCubit, HomeCardState>(
      bloc: _card,
      builder: (context, state) {
        final cart = context.watch<CartCubit>();
        final inCart = cart.state.items
            .where((item) => item.id == 'home-pixel9')
            .firstOrNull;
        final post = homeProductPost(
          title: widget.title,
          imageUrl: widget.imageUrl,
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            HomeSellerHeader(
              seller: widget.seller,
              onPressed: () => openHomeSeller(context, post, widget.seller),
            ),
            Material(
              color: Theme.of(context).colorScheme.surface,
              child: InkWell(
                onTap: () => openHomePost(context, post, widget.seller),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    HomeProductImage(
                      imageUrl: widget.imageUrl,
                      title: widget.title,
                      attempt: _card.state.imageAttempt,
                      onRetry: _card.retryImage,
                    ),
                    HomeEngagementBar(
                      isLiked: _card.state.liked,
                      onAddToCart: cart.state.loading ? null : _toggleCart,
                      isInCart: inCart != null,
                      cartCount: inCart == null
                          ? '0'
                          : cartQuantity(inCart.quantity),
                      isBookmarked: _card.state.bookmarked,
                      onLike: () => _card.toggleLike(),
                      onBookmark: () async {
                        final success = await _card.toggleBookmark(
                          post: post,
                          seller: widget.seller,
                        );
                        if (!success && context.mounted) {
                          AppToast.show(
                            context,
                            message: SavedPostsStrings.saveFailed,
                            type: AppToastType.error,
                          );
                        } else if (success &&
                            context.mounted &&
                            _card.state.bookmarked) {
                          AppToast.success(context, SavedPostsStrings.saved);
                        }
                      },
                      onCommentsPressed: () =>
                          openPostCommentsSheet(context, postId: post.id),
                      onSharePressed: () => openPostShareSheet(
                        context,
                        postId: post.id,
                        postText: [
                          post.title,
                          post.caption,
                        ].where((text) => text.trim().isNotEmpty).join('\n\n'),
                      ),
                    ),
                    HomeProductDetails(title: widget.title),
                    HomeProductPrice(post: post),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, thickness: .5),
          ],
        );
      },
    );
  }
}
