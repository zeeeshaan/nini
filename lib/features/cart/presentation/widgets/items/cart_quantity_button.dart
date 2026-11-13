// dart format width=100
import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

import '../../../domain/models/cart_item.dart';
import '../../helpers/cart_format.dart';
import '../../helpers/cart_labels.dart';

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
                      textDirection: TextDirection.rtl,
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
