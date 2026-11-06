import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_detail/presentation/widgets/pricing/post_pricing.dart';
import 'package:nini/features/post_detail/presentation/widgets/quantity_selector/post_quantity_selector.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostPurchaseActions extends StatelessWidget {
  const PostPurchaseActions({
    super.key,
    required this.post,
    required this.quantity,
    required this.maximum,
    required this.onQuantityChanged,
    this.onEditQuantity,
    this.onAddToCart,
  });

  final PostItem post;
  final int quantity;
  final int maximum;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onEditQuantity;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      LayoutBuilder(
        builder: (context, constraints) => Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 16,
          runSpacing: 12,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(maxWidth: constraints.maxWidth),
              child: PostPricing(post: post),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              textDirection: TextDirection.ltr,
              children: [
                PostQuantitySelector(
                  quantity: quantity,
                  maximum: maximum,
                  unitLabel: post.details.unit?.label ?? AppStrings.unitPiece,
                  onChanged: onQuantityChanged,
                  onEdit: onEditQuantity,
                ),
                const SizedBox(width: 12),
                IconButton.filledTonal(
                  tooltip: AppStrings.addToCart,
                  onPressed: onAddToCart,
                  style: IconButton.styleFrom(
                    minimumSize: const Size(48, 48),
                    backgroundColor: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .12),
                  ),
                  icon: AppIcon(
                    AppIcons.shoppingBag,
                    size: 24,
                    color: Theme.of(context).colorScheme.onSurface.withValues(
                      alpha: onAddToCart != null ? 1 : .4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ],
  );
}
