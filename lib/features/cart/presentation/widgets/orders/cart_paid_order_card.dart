import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/cart/domain/models/cart_order_status.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/cart/presentation/helpers/cart_labels.dart';
import 'package:nini/features/cart/presentation/widgets/items/cart_item_image.dart';
import 'package:nini/features/payment/presentation/helpers/receipt_navigation.dart';

class CartPaidOrderCard extends StatelessWidget {
  const CartPaidOrderCard({super.key, required this.order, this.onOpen});
  final CartOrder order;
  final VoidCallback? onOpen;
  @override
  Widget build(BuildContext context) {
    if (order.items.isEmpty) return const SizedBox.shrink();
    final item = order.items.first;
    final colors = Theme.of(context).colorScheme;
    final statusColor =
        order.status == CartOrderStatus.disputed ||
            order.status == CartOrderStatus.canceled
        ? AppColors.red
        : AppColors.walletCredit;
    return Material(
      color: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen ?? () => openSavedInvoice(context, order.id),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            order.status?.label ?? '',
                            style: AppTextStyles.micro.copyWith(
                              color: AppColors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cartItemTitle(item),
                            textAlign: TextAlign.right,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.compactBodyBold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      order.items.length > 1
                          ? ReceiptStrings.moreItems(order.items.length - 1)
                          : cartItemCategory(item),
                      textAlign: TextAlign.right,
                      style: AppTextStyles.smallPrint.copyWith(
                        color: colors.onSurface.withValues(alpha: .4),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Wrap(
                      alignment: WrapAlignment.end,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      children: [
                        TextButton(
                          onPressed:
                              onOpen ??
                              () => openSavedInvoice(context, order.id),
                          child: const Text(
                            ReceiptStrings.viewInvoice,
                            style: AppTextStyles.helperBold,
                          ),
                        ),
                        Text(
                          cartMoney(order.total),
                          textAlign: TextAlign.right,
                          style: AppTextStyles.pageTitleBold,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              SizedBox.square(
                dimension: 82,
                child: CartItemImage(
                  url: item.imageUrl ?? item.seller?.avatarAsset,
                  title: cartItemTitle(item),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
