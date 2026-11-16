// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/skeleton/list_tile_skeleton.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/checkout/cart_checkout.dart';
import '../widgets/common/cart_empty_state.dart';
import '../widgets/common/cart_header.dart';
import '../widgets/items/cart_items_list.dart';
import '../widgets/items/cart_undo_notice.dart';
import '../widgets/orders/cart_order_history.dart';
import '../widgets/orders/cart_paid_order_card.dart';
import '../widgets/common/cart_storage_notice.dart';
import '../widgets/common/cart_tabs.dart';
import '../widgets/orders/cart_status_filter.dart';

/// One screen composes named widgets; checkout retains the dashboard navigation.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onBack, this.active = true});
  final VoidCallback onBack;
  final bool active;
  void _back(CartCubit cart) {
    if (cart.state.stage == CartStage.cart) {
      onBack();
    } else {
      cart.back();
    }
  }

  Widget _content(CartState state) {
    if (state.loading && state.items.isEmpty && state.orders.isEmpty) {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, index) => const ListTileSkeleton(),
      );
    }
    if (state.stage == CartStage.checkout) return CartCheckout(state: state);
    if (state.tab == CartTab.history) {
      return CartOrderHistory(orders: state.purchases, filtered: state.statusFilter != null);
    }
    if (state.tab == CartTab.sales) {
      final sales = state.sales;
      if (sales.isNotEmpty) return CartOrderHistory(orders: sales, asProvider: true);
      return const CartEmptyState(title: CartStrings.noSales, message: CartStrings.salesHelp);
    }
    return CartItemsList(
      state: state,
      leading: [
        for (final order in state.purchases.where((order) => order.isPaidReceipt))
          CartPaidOrderCard(key: ValueKey(order.id), order: order),
      ],
    );
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<CartCubit, CartState>(
    builder: (context, state) {
      final cart = context.read<CartCubit>();
      final title = switch (state.stage) {
        CartStage.cart => CartStrings.cart,
        CartStage.checkout => CartStrings.checkout,
      };
      return Localizations.override(
        context: context,
        locale: const Locale('fa', 'IR'),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: PopScope(
            canPop: !active,
            onPopInvokedWithResult: (didPop, _) {
              if (!didPop && active) _back(cart);
            },
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: Column(
                  children: [
                    CartHeader(
                      title: title,
                      onBack: state.stage == CartStage.checkout ? () => _back(cart) : null,
                    ),
                    if (state.stage == CartStage.cart)
                      CartTabs(selected: state.tab, onSelected: cart.selectTab),
                    if (state.stage == CartStage.cart && state.statusFilter != null)
                      CartStatusFilter(
                        status: state.statusFilter!,
                        onClear: () => cart.filterByStatus(null),
                      ),
                    if (state.storageError) CartStorageNotice(onRetry: cart.retryStorage),
                    Expanded(child: _content(state)),
                    if (state.stage == CartStage.cart && state.tab == CartTab.cart)
                      AnimatedSize(
                        duration: MediaQuery.disableAnimationsOf(context)
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        alignment: Alignment.bottomCenter,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxHeight: MediaQuery.sizeOf(context).height * .25,
                          ),
                          child: SingleChildScrollView(
                            padding: state.removals.isEmpty
                                ? EdgeInsets.zero
                                : const EdgeInsets.fromLTRB(16, 8, 16, 12),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                for (final removal in state.removals)
                                  Padding(
                                    key: ValueKey(removal),
                                    padding: const EdgeInsets.only(top: 6),
                                    child: CartUndoNotice(removal: removal),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    },
  );
}
