import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/post_detail_strings.dart';
import 'package:nini/core/theme/app_theme.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/cubit/cart_cubit.dart';
import 'package:nini/features/cart/presentation/widgets/dialogs/cart_amount_dialog.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_purchase_actions.dart';
import 'package:nini/features/post_detail/presentation/widgets/purchase_actions/post_service_purchase_actions.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class PostDetailBottomBar extends StatelessWidget {
  const PostDetailBottomBar({super.key, required this.post, this.seller});

  final PostItem post;
  final PostSeller? seller;

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
      allowZero: true,
      title: PostDetailStrings.quantity,
    );
    if (value != null && context.mounted) {
      context.read<PostDetailCubit>().selectQuantity(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final quantity = context.select(
      (PostDetailCubit cubit) => cubit.state.quantity,
    );
    final cart = context.watch<CartCubit?>();
    final item = postCartItem(post, seller: seller);
    final inCart = cart?.state.items
        .where((entry) => entry.id == post.id)
        .firstOrNull;
    final available = (item?.maxQuantity ?? 0) - (inCart?.quantity ?? 0);
    final maximum = cart != null && available > 0 ? available : 0;
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
                  vertical: 12,
                ),
                child: post.isService
                    ? PostServicePurchaseActions(
                        post: post,
                        quantity: quantity,
                        maximum: maximum,
                        onQuantityChanged: context
                            .read<PostDetailCubit>()
                            .selectQuantity,
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
                        onQuantityChanged: context
                            .read<PostDetailCubit>()
                            .selectQuantity,
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
