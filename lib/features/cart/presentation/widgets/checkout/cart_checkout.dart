// dart format width=100
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';

import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../dialogs/cart_amount_dialog.dart';
import '../items/cart_item_card.dart';
import 'cart_payment_summary.dart';
import '../common/cart_section.dart';

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
        CartSection(
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
        CartSection(
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
        const CartSection(
          title: CartStrings.escrow,
          child: Text(
            CartStrings.escrowHelp,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.checkoutHelp,
          ),
        ),
      ],
    );
  }
}
