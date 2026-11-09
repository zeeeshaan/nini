import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/post_detail_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_pricing.dart';
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
  });

  final PostItem post;
  final int quantity;
  final int maximum;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback? onEditQuantity;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 16,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: constraints.maxWidth),
          child: Wrap(
            spacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              PostPricing(post: post),
              if (post.details.unit == null)
                const Text(
                  AppStrings.unitSession,
                  style: AppTextStyles.body,
                  textAlign: TextAlign.right,
                ),
            ],
          ),
        ),
        PostQuantitySelector(
          quantity: quantity,
          maximum: maximum,
          unitLabel: PostDetailStrings.unit(
            post.details.unit ?? PostUnit.session,
          ),
          onChanged: onQuantityChanged,
          onEdit: onEditQuantity,
        ),
      ],
    ),
  );
}
