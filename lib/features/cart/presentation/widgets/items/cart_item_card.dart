// dart format width=100
import 'dart:math' as math;

import 'package:nini/core/theme/app_text_styles.dart';

import 'package:flutter/material.dart';

import '../../../domain/models/cart_item.dart';
import '../../helpers/cart_format.dart';
import '../../helpers/cart_labels.dart';
import 'cart_item_image.dart';
import 'cart_item_badge.dart';
import 'cart_quantity_button.dart';
import 'cart_service_item_card.dart';

class CartItemCard extends StatelessWidget {
  const CartItemCard({
    super.key,
    required this.item,
    required this.onQuantity,
    this.onTap,
    this.readOnly = false,
  });
  final CartItem item;
  final VoidCallback onQuantity;
  final VoidCallback? onTap;
  final bool readOnly;
  @override
  Widget build(BuildContext context) {
    if (item.isService) return CartServiceItemCard(item: item, onTap: onTap);
    final colors = Theme.of(context).colorScheme;
    final badge = cartItemBadgeLabel(item);
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final imageSize = math.min(110.0, constraints.maxWidth * .26);
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (badge != null) CartItemBadge(label: badge),
                              Expanded(
                                child: Text(
                                  cartItemTitle(item),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.right,
                                  textDirection: TextDirection.rtl,
                                  style: AppTextStyles.compactBodyBold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            cartItemCategory(item),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.rtl,
                            style: AppTextStyles.label.copyWith(
                              color: colors.onSurface.withValues(alpha: .25),
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              Flexible(
                                child: readOnly
                                    ? Text(
                                        '${cartMoney(item.quantity)} ${cartUnit(item.unit, item.quantity)}',
                                        textDirection: TextDirection.rtl,
                                        textAlign: TextAlign.right,
                                        style: AppTextStyles.helper,
                                      )
                                    : CartQuantityButton(item: item, onTap: onQuantity),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cartMoney(item.total),
                                  textDirection: TextDirection.rtl,
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.pageTitleBold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: CartItemImage(url: item.imageUrl, title: cartItemTitle(item)),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
