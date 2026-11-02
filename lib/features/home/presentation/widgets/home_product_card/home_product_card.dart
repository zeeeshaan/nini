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
  });

  final String imageUrl;
  final String title;
  final VoidCallback? onViewCart;

  @override
  State<HomeProductCard> createState() => _HomeProductCardState();
}

class _HomeProductCardState extends State<HomeProductCard>
    with AutomaticKeepAliveClientMixin {
  bool _isLiked = true;
  bool _isBookmarked = false;

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
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HomeProductImage(imageUrl: widget.imageUrl, title: widget.title),
        HomeEngagementBar(
          isLiked: _isLiked,
          onAddToCart: _addToCart,
          isBookmarked: _isBookmarked,
          onLike: () => setState(() => _isLiked = !_isLiked),
          onBookmark: () => setState(() => _isBookmarked = !_isBookmarked),
        ),
        HomeProductDetails(title: widget.title),
        const HomeProductPrice(),
        const Divider(height: 1, thickness: .5),
      ],
    );
  }
}
