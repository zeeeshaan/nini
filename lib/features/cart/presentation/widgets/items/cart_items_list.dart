// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_button/app_button.dart';

import '../../cubit/cart_cubit.dart';
import '../../cubit/cart_state.dart';
import '../../helpers/cart_format.dart';
import '../../helpers/cart_checkout_navigation.dart';
import '../dialogs/cart_amount_dialog.dart';
import '../dialogs/cart_remove_dialog.dart';
import 'cart_delete_background.dart';
import '../common/cart_empty_state.dart';
import 'cart_item_card.dart';

class CartItemsList extends StatelessWidget {
  const CartItemsList({super.key, required this.state, this.leading = const []});
  final CartState state;
  final List<Widget> leading;
  @override
  Widget build(BuildContext context) {
    if (state.items.isEmpty && leading.isEmpty) {
      return const CartEmptyState(title: CartStrings.empty, message: CartStrings.emptyHelp);
    }
    final items = state.visibleItems;
    if (items.isEmpty && leading.isEmpty) {
      return const CartEmptyState(title: CartStrings.noMatches, message: CartStrings.noMatchesHelp);
    }
    final cart = context.read<CartCubit>();
    return ListView.separated(
      key: const PageStorageKey('cart-items'),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: leading.length + items.length + (items.isNotEmpty ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index < leading.length) return leading[index];
        final itemIndex = index - leading.length;
        if (itemIndex == items.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 32, bottom: 12),
            child: Directionality(
              textDirection: TextDirection.ltr,
              child: AppButton(
                key: const ValueKey('cart-checkout'),
                label:
                    '${CartStrings.checkout} · ${cartMoney(state.visibleTotal)} ${CartStrings.toman}',
                onPressed: () => openCartCheckout(context),
              ),
            ),
          );
        }
        final item = items[itemIndex];
        return Semantics(
          customSemanticsActions: {
            CustomSemanticsAction(label: CartStrings.remove): () async {
              final confirmed = await showCartRemoveDialog(context, itemTitle: item.title);
              if (confirmed && context.mounted) cart.removeWithUndo(item.id);
            },
          },
          child: Dismissible(
            key: ValueKey('cart-item-${item.id}'),
            // CartScreen keeps LTR geometry: this is a physical right-to-left swipe.
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              final confirmed = await showCartRemoveDialog(context, itemTitle: item.title);
              return confirmed && context.mounted;
            },
            onDismissed: (_) => cart.removeWithUndo(item.id),
            background: const CartDeleteBackground(),
            child: CartItemCard(
              item: item,
              onTap: () => openCartCheckout(context, itemId: item.id),
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
