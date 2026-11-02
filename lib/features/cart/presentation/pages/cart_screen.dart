// dart format width=100
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/shared/widgets/app_loader/app_loader.dart';

import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../widgets/cart_checkout/cart_checkout.dart';
import '../widgets/cart_empty_state/cart_empty_state.dart';
import '../widgets/cart_header/cart_header.dart';
import '../widgets/cart_items_list/cart_items_list.dart';
import '../widgets/cart_order_history/cart_order_history.dart';
import '../widgets/cart_storage_notice/cart_storage_notice.dart';
import '../widgets/cart_tabs/cart_tabs.dart';
import '../widgets/cart_status_menu/cart_status_menu.dart';
import '../widgets/cart_status_filter/cart_status_filter.dart';

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
    if (state.loading) return const Center(child: AppLoader());
    if (state.stage == CartStage.checkout) return CartCheckout(state: state);
    if (state.tab == CartTab.history) {
      return CartOrderHistory(orders: state.visibleOrders, filtered: state.statusFilter != null);
    }
    if (state.tab == CartTab.sales) {
      return const CartEmptyState(title: CartStrings.noSales, message: CartStrings.salesHelp);
    }
    return CartItemsList(state: state);
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
                      onBack: () => _back(cart),
                      trailing: state.stage == CartStage.cart
                          ? CartStatusMenu(
                              selected: state.statusFilter,
                              onSelected: cart.filterByStatus,
                            )
                          : null,
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
