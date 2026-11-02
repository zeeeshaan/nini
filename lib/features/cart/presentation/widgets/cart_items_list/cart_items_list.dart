// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../helpers/cart_format.dart';
import '../cart_amount_dialog/cart_amount_dialog.dart';
import '../cart_delete_background/cart_delete_background.dart';
import '../cart_empty_state/cart_empty_state.dart';
import '../cart_item_card/cart_item_card.dart';

class CartItemsList extends StatelessWidget {
  const CartItemsList({super.key, required this.state});
  final CartState state;
  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty) {
      return const CartEmptyState(title: CartStrings.empty, message: CartStrings.emptyHelp);
    }
    final items = state.visibleItems;
    if (items.isEmpty) {
      return const CartEmptyState(title: CartStrings.noMatches, message: CartStrings.noMatchesHelp);
    }
    final cart = context.read<CartCubit>();
    return ListView.separated(
      key: const PageStorageKey('cart-items'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: items.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 12),
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: AppButton(
                key: const ValueKey('cart-checkout'),
                label:
                    '${CartStrings.checkout} · ${cartMoney(state.visibleTotal)} ${CartStrings.toman}',
                onPressed: () => cart.checkout(),
              ),
            ),
          );
        }
        final item = items[index];
        return Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: CartStrings.remove): () => cart.remove(item.id),
          },
          child: Dismissible(
            key: ValueKey('cart-item-${item.id}'),
            // CartScreen keeps LTR geometry: this is a physical right-to-left swipe.
            direction: DismissDirection.endToStart,
            onDismissed: (_) => cart.remove(item.id),
            background: const CartDeleteBackground(),
            child: CartItemCard(
              item: item,
              onTap: () => cart.checkout(itemId: item.id),
              onQuantity: () async {
                final amount = await showCartAmountDialog(
                  context,
                  value: item.quantity,
                  wholeUnits: item.wholeUnits,
                  maximum: item.maxQuantity,
                );
                if (amount != null && context.mounted) cart.updateQuantity(item.id, amount);
              },
            ),
          ),
        );
      },
    );
  }
}
