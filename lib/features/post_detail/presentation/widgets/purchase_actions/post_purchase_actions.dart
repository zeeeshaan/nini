import 'package:flutter/material.dart';
import 'package:nini/core/localization/post_detail_strings.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_pricing.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_quantity_selector.dart';
import 'package:nini/shared/models/post/post_item.dart';

class PostPurchaseActions extends StatelessWidget {
  const PostPurchaseActions({
    super.key,
    required this.post,
    required this.quantity,
    required this.maximum,
    required this.onQuantityChanged,
    this.onEditQuantity,
  });

  final PostItem post;
  final int quantity;
  final int maximum;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onEditQuantity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final prices = FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: PostPricing(post: post),
      );
      final selector = PostQuantitySelector(
        compact: true,
        quantity: quantity,
        maximum: maximum,
        unitLabel: PostDetailStrings.unit(post.details.unit ?? PostUnit.piece),
        onChanged: onQuantityChanged,
        onEdit: onEditQuantity,
      );
      if (constraints.maxWidth < 220 ||
          MediaQuery.textScalerOf(context).scale(14) > 21) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(alignment: Alignment.centerLeft, child: prices),
            const SizedBox(height: 8),
            Align(alignment: Alignment.centerRight, child: selector),
          ],
        );
      }
      return Row(
        textDirection: TextDirection.ltr,
        children: [
          Expanded(child: prices),
          const SizedBox(width: 16),
          selector,
        ],
      );
    },
  );
}
