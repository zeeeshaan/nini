// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/cart_strings.dart';

import '../../../domain/models/cart_order.dart';
import '../../helpers/cart_format.dart';
import '../cart_empty_state/cart_empty_state.dart';
import '../cart_item_card/cart_item_card.dart';
import '../cart_item_badge/cart_item_badge.dart';

class CartOrderHistory extends StatelessWidget {
  const CartOrderHistory({super.key, required this.orders, this.filtered = false});
  final List<CartOrder> orders;
  final bool filtered;
  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return CartEmptyState(
        title: filtered ? CartStrings.noMatches : CartStrings.noOrders,
        message: filtered ? CartStrings.noMatchesHelp : null,
      );
    }
    return ListView.separated(
      key: const PageStorageKey('cart-order-history'),
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        final order = orders[index];
        final date = AppStrings.persianDigits(
          MaterialLocalizations.of(context).formatShortDate(order.createdAt),
        );
        return ExpansionTile(
          key: PageStorageKey('order-${order.id}'),
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor),
          ),
          title: Text(
            CartStrings.previewOrder,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          subtitle: Text(
            '$date · ${cartMoney(order.total)} ${CartStrings.toman}',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),
          childrenPadding: const EdgeInsets.all(12),
          expandedCrossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (order.status != null)
              Align(
                alignment: Alignment.centerRight,
                child: CartItemBadge(label: order.status!.label),
              ),
            const SizedBox(height: 8),
            Text(
              '${CartStrings.receipt}: ${order.id}',
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                order.method.label,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),
            const SizedBox(height: 8),
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CartItemCard(item: item, onQuantity: () {}, readOnly: true),
              ),
          ],
        );
      },
    );
  }
}
