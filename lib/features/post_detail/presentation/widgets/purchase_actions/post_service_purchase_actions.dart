import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/post_detail_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_quantity_selector.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// Service price and quantity; purchasing is handled by the engagement-row bag.
class PostServicePurchaseActions extends StatelessWidget {
  const PostServicePurchaseActions({
    super.key,
    required this.post,
    required this.quantity,
    required this.maximum,
    required this.onQuantityChanged,
    this.onEditQuantity,
    this.trailing,
  });

  final PostItem post;
  final int quantity;
  final int maximum;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onEditQuantity;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    final amount = parseCartAmount(
      post.price.replaceAll(RegExp(r'[,٬\s]'), ''),
    );
    final price = amount == null
        ? AppStrings.persianDigits(post.price)
        : cartMoney(amount);
    final original = post.originalPrice.trim();
    final hasDiscount = original.isNotEmpty && original != post.price.trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final prices = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            textDirection: TextDirection.ltr,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: TextDirection.ltr,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  if (post.price.trim().isNotEmpty)
                    Text(
                      price,
                      textDirection: TextDirection.ltr,
                      style: AppTextStyles.homePostPrice.copyWith(
                        fontSize: hasDiscount
                            ? AppTextStyles.body.fontSize
                            : AppTextStyles.heading.fontSize,
                        color: foreground,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  const SizedBox(width: 8),
                  Text(
                    post.details.unit?.label ?? AppStrings.unitSession,
                    style: AppTextStyles.body.copyWith(color: foreground),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
              if (hasDiscount)
                Text(
                  AppStrings.persianDigits(original),
                  textDirection: TextDirection.ltr,
                  style: AppTextStyles.homePostPrice.copyWith(
                    fontSize: AppTextStyles.heading.fontSize,
                    color: foreground,
                    decoration: TextDecoration.lineThrough,
                    decorationColor: foreground,
                  ),
                  textAlign: TextAlign.right,
                ),
            ],
          ),
        );
        final selector = PostQuantitySelector(
          compact: true,
          quantity: quantity,
          maximum: maximum,
          unitLabel: PostDetailStrings.unit(
            post.details.unit ?? PostUnit.session,
          ),
          onChanged: onQuantityChanged,
          onEdit: onEditQuantity,
        );
        if (constraints.maxWidth < 220 ||
            MediaQuery.textScalerOf(context).scale(14) > 21) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(alignment: Alignment.centerLeft, child: prices),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: trailing == null
                    ? selector
                    : Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 8,
                        runSpacing: 8,
                        children: [selector, trailing!],
                      ),
              ),
            ],
          );
        }
        return Row(
          textDirection: TextDirection.ltr,
          children: [
            Expanded(child: prices),
            const SizedBox(width: 16),
            selector,
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        );
      },
    );
  }
}
