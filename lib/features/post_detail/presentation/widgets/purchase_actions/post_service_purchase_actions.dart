import 'package:flutter/material.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/post_detail/presentation/widgets/pricing/post_pricing.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

/// The service footer adds one service unit without product quantity controls.
class PostServicePurchaseActions extends StatelessWidget {
  const PostServicePurchaseActions({
    super.key,
    required this.post,
    this.onAddToCart,
  });

  final PostItem post;
  final VoidCallback? onAddToCart;

  @override
  Widget build(BuildContext context) => Row(
    textDirection: TextDirection.ltr,
    children: [
      Expanded(
        child: Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PostPricing(post: post),
            if (post.details.unit == null)
              const Text(AppStrings.unitSession, style: AppTextStyles.body),
          ],
        ),
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
        icon: const AppIcon(AppIcons.shoppingBag, size: 24),
      ),
    ],
  );
}
