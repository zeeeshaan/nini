// dart format width=100
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hywork/core/constants/app_icons/app_icons.dart';
import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/core/theme/app_colors/app_colors.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/models/cart_item.dart';
import 'package:hywork/features/cart/utils/cart_helpers.dart';
import 'package:hywork/features/cart/widgets/cart_items/cart_service_item_card.dart';
import 'package:hywork/shared/widgets/app_icons/app_icon.dart';

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
                                  textDirection: TextDirection.ltr,
                                  style: AppTextStyles.compactBodyBold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            cartItemCategory(item),
                            textAlign: TextAlign.right,
                            textDirection: TextDirection.ltr,
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
                                        textDirection: TextDirection.ltr,
                                        textAlign: TextAlign.right,
                                        style: AppTextStyles.helper,
                                      )
                                    : CartQuantityButton(item: item, onTap: onQuantity),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  cartMoney(item.total),
                                  textDirection: TextDirection.ltr,
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

class CartItemBadge extends StatelessWidget {
  const CartItemBadge({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(right: 6, top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(color: colors.onSurface, borderRadius: BorderRadius.circular(12)),
      child: Text(
        label,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.right,
        style: AppTextStyles.micro.copyWith(color: colors.surface),
      ),
    );
  }
}

class CartItemImage extends StatelessWidget {
  const CartItemImage({super.key, required this.url, required this.title});
  final String? url;
  final String title;
  ImageProvider _provider(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return NetworkImage(path);
    if (path.startsWith('assets/')) return AssetImage(path);
    return FileImage(File(path));
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, size) {
      final placeholder = Theme.of(context).brightness == Brightness.light
          ? AppColors.cartThumbnail
          : Theme.of(context).colorScheme.surfaceContainerHighest;
      return ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: ColoredBox(
          color: placeholder,
          child: url == null
              ? const SizedBox.expand()
              : Image(
                  image: _provider(url!),
                  fit: BoxFit.contain,
                  semanticLabel: title,
                  errorBuilder: (_, _, _) =>
                      const Center(child: AppIcon(AppIcons.imageUnavailable, size: 24)),
                ),
        ),
      );
    },
  );
}

class CartQuantityButton extends StatelessWidget {
  const CartQuantityButton({super.key, required this.item, required this.onTap});
  final CartItem item;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: CartStrings.quantity,
      child: Semantics(
        button: true,
        label: CartStrings.quantity,
        child: InkWell(
          key: ValueKey('quantity-${item.id}'),
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: colors.onSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIcons.add, size: 20, color: colors.surface),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      '${cartQuantity(item.quantity)} ${cartUnit(item.unit, item.quantity)}',
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.smallPrint.copyWith(color: colors.surface),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
