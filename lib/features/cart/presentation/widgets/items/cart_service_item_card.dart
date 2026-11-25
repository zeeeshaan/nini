import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/cart/presentation/helpers/cart_labels.dart';
import 'package:nini/features/cart/presentation/widgets/items/cart_item_image.dart';

/// Compact service summary, without product pieces or quantity controls.
class CartServiceItemCard extends StatelessWidget {
  const CartServiceItemCard({super.key, required this.item, this.onTap});

  final CartItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
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
              final imageSize = math.min(110.0, constraints.maxWidth * .30);
              return IntrinsicHeight(
                child: Row(
                  textDirection: TextDirection.ltr,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            cartItemTitle(item),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.bodyBold,
                            textDirection: TextDirection.ltr,
                          ),
                          Text(
                            cartItemCategory(item),
                            textAlign: TextAlign.right,
                            style: AppTextStyles.label.copyWith(
                              color: colors.onSurface.withValues(alpha: .35),
                            ),
                            textDirection: TextDirection.ltr,
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          Text(
                            cartMoney(item.total),
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.right,
                            style: AppTextStyles.amount.copyWith(
                              fontWeight: AppTextStyles.extraBold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: imageSize,
                      height: imageSize,
                      child: CartItemImage(
                        url: item.imageUrl?.isNotEmpty == true
                            ? item.imageUrl
                            : item.seller?.avatarAsset,
                        title: cartItemTitle(item),
                      ),
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
