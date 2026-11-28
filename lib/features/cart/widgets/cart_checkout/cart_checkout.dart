// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/cubit/cart_state.dart';
import 'package:hywork/features/cart/widgets/cart_dialogs/cart_dialogs.dart';
import 'package:hywork/features/cart/widgets/cart_checkout/cart_payment_summary.dart';
import 'package:hywork/features/cart/widgets/cart_items/cart_item_card.dart';

class CartCheckout extends StatelessWidget {
  const CartCheckout({super.key, required this.state});
  final CartState state;
  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartCubit>();
    return ListView(
      key: const PageStorageKey('cart-checkout-details'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      children: [
        _CartSection(
          title: CartStrings.orderDetails,
          child: Column(
            children: [
              for (final item in state.checkoutItems)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: CartItemCard(
                    item: item,
                    onQuantity: () async {
                      final amount = await showCartAmountDialog(
                        context,
                        value: item.quantity,
                        wholeUnits: item.wholeUnits,
                        maximum: item.maxQuantity,
                      );
                      if (amount != null && context.mounted) {
                        cart.updateQuantity(item.id, amount);
                      }
                    },
                  ),
                ),
            ],
          ),
        ),
        _CartSection(
          title: CartStrings.paymentDetails,
          child: CartPaymentSummary(
            state: state,
            onCharges: () async {
              final amount = await showCartAmountDialog(
                context,
                value: state.charges,
                allowZero: true,
                title: CartStrings.charges,
              );
              if (amount != null && context.mounted) cart.setCharges(amount);
            },
          ),
        ),
        const SizedBox(height: 16),
        const _CartSection(
          title: CartStrings.escrow,
          child: Text(
            CartStrings.escrowHelp,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.checkoutHelp,
          ),
        ),
      ],
    );
  }
}

class _CartSection extends StatelessWidget {
  const _CartSection({required this.title, required this.child});
  final String title;
  final Widget child;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
          child: Text(
            title,
            textAlign: TextAlign.right,
            textDirection: TextDirection.ltr,
            style: AppTextStyles.bodyBold,
          ),
        ),
        child,
      ],
    ),
  );
}
