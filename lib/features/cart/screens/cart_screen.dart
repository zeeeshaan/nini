// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/features/cart/cubit/cart_cubit.dart';
import 'package:hywork/features/cart/cubit/cart_state.dart';
import 'package:hywork/features/cart/widgets/cart_checkout/cart_checkout.dart';
import 'package:hywork/features/cart/widgets/cart_empty_state/cart_empty_state.dart';
import 'package:hywork/features/cart/widgets/cart_header/cart_header.dart';
import 'package:hywork/features/cart/widgets/cart_items/cart_items_list.dart';
import 'package:hywork/features/cart/widgets/cart_loading/cart_loading.dart';
import 'package:hywork/features/cart/widgets/cart_orders/cart_order_history.dart';
import 'package:hywork/features/cart/widgets/cart_orders/cart_paid_order_card.dart';
import 'package:hywork/features/cart/widgets/cart_orders/cart_status_filter.dart';
import 'package:hywork/features/cart/widgets/cart_storage/cart_storage_notice.dart';
import 'package:hywork/features/cart/widgets/cart_undo/cart_undo_notice.dart';

/// Composes cart stages, tabs, and notices without embedding widget details.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key, required this.onBack, this.active = true});

  final VoidCallback onBack;
  final bool active;

  void _handleBack(CartCubit cart) {
    if (cart.state.stage == CartStage.cart) {
      onBack();
    } else {
      cart.back();
    }
  }

  Widget _buildContent(CartState state) {
    if (state.loading && state.items.isEmpty && state.orders.isEmpty) {
      return const CartLoading();
    }
    if (state.stage == CartStage.checkout) {
      return CartCheckout(state: state);
    }
    if (state.tab == CartTab.history) {
      return CartOrderHistory(orders: state.purchases, filtered: state.statusFilter != null);
    }
    if (state.tab == CartTab.sales) {
      final sales = state.sales;
      if (sales.isNotEmpty) {
        return CartOrderHistory(orders: sales, asProvider: true);
      }
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

  Widget _buildUndoPanel(BuildContext context, CartState state) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    return AnimatedSize(
      duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 200),
      alignment: Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .25),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final cart = context.read<CartCubit>();
        final title = switch (state.stage) {
          CartStage.cart => CartStrings.cart,
          CartStage.checkout => CartStrings.checkout,
        };
        final showCartChrome = state.stage == CartStage.cart;
        final showUndo = showCartChrome && state.tab == CartTab.cart;

        return Localizations.override(
          context: context,
          locale: const Locale('en'),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: PopScope(
              canPop: !active,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && active) _handleBack(cart);
              },
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Column(
                    children: [
                      CartHeader(
                        title: title,
                        onBack: state.stage == CartStage.checkout ? () => _handleBack(cart) : null,
                      ),
                      if (showCartChrome) CartTabs(selected: state.tab, onSelected: cart.selectTab),
                      if (showCartChrome && state.statusFilter != null)
                        CartStatusFilter(
                          status: state.statusFilter!,
                          onClear: () => cart.filterByStatus(null),
                        ),
                      if (state.storageError) CartStorageNotice(onRetry: cart.retryStorage),
                      Expanded(child: _buildContent(state)),
                      if (showUndo) _buildUndoPanel(context, state),
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
}
