import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/widgets/home_seller_header/home_seller_header.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/home/presentation/cubit/home_card_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/shared/models/post/post_unit.dart';

import 'package:nini/features/home/presentation/widgets/home_engagement_bar/home_engagement_bar.dart';
import 'package:nini/features/home/presentation/widgets/home_product_details/home_product_details.dart';
import 'package:nini/features/home/presentation/widgets/home_product_image/home_product_image.dart';
import 'package:nini/features/home/presentation/widgets/home_product_price/home_product_price.dart';

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
  final _card = HomeCardCubit();

  @override
  bool get wantKeepAlive => true;

  void _addToCart() {
    final cart = context.read<CartCubit>();
    final added = cart.add(
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
          action: added && widget.onViewCart != null
              ? SnackBarAction(
                  label: AppStrings.viewCart,
                  onPressed: widget.onViewCart!,
                )
              : null,
          content: Text(
            added
                ? AppStrings.cartAdded
                : cart.state.storageError
                ? AppStrings.cartStorageError
                : AppStrings.cartStockExceeded,
            textDirection: TextDirection.rtl,
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
                      onAddToCart: _addToCart,
                      isBookmarked: _card.state.bookmarked,
                      onLike: () => _card.toggleLike(),
                      onBookmark: () => _card.toggleBookmark(),
                    ),
                    HomeProductDetails(title: widget.title),
                    const HomeProductPrice(),
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
