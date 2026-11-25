import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/post_detail_strings.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/theme/app_theme/app_theme.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/widgets/dialogs/cart_amount_dialog.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_purchase_actions.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_service_purchase_actions.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class PostDetailBottomBar extends StatelessWidget {
  const PostDetailBottomBar({
    super.key,
    required this.post,
    this.seller,
    this.trailing,
  });

  final PostItem post;
  final PostSeller? seller;
  final Widget? trailing;

  void _changeQuantity(BuildContext context, int value) {
    final cart = context.read<CartCubit?>();
    final inCart = cart?.state.items.any((item) => item.id == post.id) == true;
    if (inCart && !cart!.updateQuantity(post.id, value)) {
      AppToast.error(
        context,
        cart.state.storageError
            ? AppStrings.cartStorageError
            : AppStrings.cartStockExceeded,
      );
      return;
    }
    context.read<PostDetailCubit>().selectQuantity(value);
  }

  Future<void> _chooseQuantity(
    BuildContext context,
    CartItem item,
    int quantity,
    int maximum,
  ) async {
    final value = await showCartAmountDialog(
      context,
      value: quantity,
      maximum: maximum,
      wholeUnits: item.wholeUnits,
      title: PostDetailStrings.quantity,
    );
    if (value != null && context.mounted) {
      _changeQuantity(context, value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final selectedQuantity = context.select(
      (PostDetailCubit cubit) => cubit.state.quantity,
    );
    final cart = context.watch<CartCubit?>();
    final item = postCartItem(post, seller: seller);
    final inCart = cart?.state.items
        .where((entry) => entry.id == post.id)
        .firstOrNull;
    final quantity = inCart?.quantity ?? selectedQuantity;
    final maximum = cart != null && !cart.state.loading
        ? (inCart ?? item)?.maxQuantity ?? 0
        : 0;
    return Theme(
      data: Theme.of(context).brightness == Brightness.dark
          ? AppTheme.light
          : AppTheme.dark,
      child: ColoredBox(
        color: colors.onSurface,
        child: SafeArea(
          top: false,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 6,
                ),
                child: post.isService
                    ? PostServicePurchaseActions(
                        post: post,
                        trailing: trailing,
                        quantity: quantity,
                        maximum: maximum,
                        onQuantityChanged: (value) =>
                            _changeQuantity(context, value),
                        onEditQuantity: item != null && maximum > 0
                            ? () => _chooseQuantity(
                                context,
                                item,
                                quantity,
                                maximum,
                              )
                            : null,
                      )
                    : PostPurchaseActions(
                        post: post,
                        quantity: quantity,
                        maximum: maximum,
                        onQuantityChanged: (value) =>
                            _changeQuantity(context, value),
                        onEditQuantity: item != null && maximum > 0
                            ? () => _chooseQuantity(
                                context,
                                item,
                                quantity,
                                maximum,
                              )
                            : null,
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
