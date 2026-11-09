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
            PostQuantitySelector(
              quantity: quantity,
              maximum: maximum,
              unitLabel: PostDetailStrings.unit(
                post.details.unit ?? PostUnit.piece,
              ),
              onChanged: onQuantityChanged,
              onEdit: onEditQuantity,
            ),
          ],
        ),
      ),
    ],
  );
}
