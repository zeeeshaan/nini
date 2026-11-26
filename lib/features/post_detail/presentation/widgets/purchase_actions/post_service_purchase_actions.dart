import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/post_detail_strings.dart';
import 'package:hywork/features/post_detail/presentation/widgets/common/post_pricing.dart';
import 'package:hywork/features/post_detail/presentation/widgets/common/post_quantity_selector.dart';
import 'package:hywork/shared/models/post/post_item.dart';

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final prices = FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: PostPricing(
            post: post,
            color: foreground,
            fallbackUnitLabel: PostDetailStrings.unitSession,
          ),
        );
        final selector = PostQuantitySelector(
          compact: true,
          quantity: quantity,
          maximum: maximum,
          // Figma quantity pill uses عدد, not the service billing unit (جلسه).
          unitLabel: PostDetailStrings.unit(PostUnit.piece),
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
