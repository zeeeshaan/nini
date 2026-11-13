import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/cart/presentation/helpers/cart_labels.dart';
import 'package:nini/features/cart/presentation/widgets/items/cart_item_image.dart';
import 'package:nini/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class OrderInformationItem extends StatelessWidget {
  const OrderInformationItem({
    super.key,
    required this.item,
    this.onQuantity,
    this.readOnly = false,
  });
  final CartItem item;
  final VoidCallback? onQuantity;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final seller = item.seller;
    return Padding(
      padding: readOnly
          ? const EdgeInsets.all(12)
          : const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (seller != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              seller.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.username,
                              textAlign: TextAlign.right,
                            ),
                            if (seller.location.isNotEmpty)
                              Text(
                                seller.location,
                                style: AppTextStyles.metadata.copyWith(
                                  color: colors.onSurface.withValues(alpha: .7),
                                ),
                                textAlign: TextAlign.right,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      SellerAvatar(
                        asset: seller.avatarAsset,
                        name: seller.name,
                        size: 24,
                      ),
                    ],
                  ),
                const SizedBox(height: 6),
                Text(
                  cartItemTitle(item),
                  textAlign: TextAlign.right,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyBold,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: readOnly
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: readOnly
                      ? Text(
                          '${cartQuantity(item.quantity)} ${item.unit.label}',
                          style: AppTextStyles.labelMedium,
                          textAlign: TextAlign.right,
                        )
                      : Tooltip(
                          message: CartStrings.quantity,
                          child: InkWell(
                            onTap: onQuantity,
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: colors.onSurface,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  AppIcon(
                                    AppIcons.add,
                                    size: 16,
                                    color: colors.surface,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${cartQuantity(item.quantity)} ${item.unit.label}',
                                    style: AppTextStyles.smallPrint.copyWith(
                                      color: colors.surface,
                                    ),
                                    textAlign: TextAlign.right,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox.square(
            dimension: 84,
            child: CartItemImage(
              url: item.imageUrl ?? seller?.avatarAsset,
              title: cartItemTitle(item),
            ),
          ),
        ],
      ),
    );
  }
}
