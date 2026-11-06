import 'package:flutter/material.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/seller_avatar/seller_avatar.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class HomeSellerHeader extends StatelessWidget {
  const HomeSellerHeader({
    super.key,
    required this.seller,
    required this.onPressed,
  });

  final PostSeller seller;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    child: Row(
      textDirection: TextDirection.ltr,
      children: [
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                seller.name,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: AppTextStyles.sellerName.fontSize,
                  fontWeight: AppTextStyles.sellerName.fontWeight,
                ),
              ),
              if (seller.location.isNotEmpty)
                Text(
                  seller.location,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: AppTextStyles.labelMedium.fontSize,
                    fontWeight: AppTextStyles.labelMedium.fontWeight,
                    color: Theme.of(context).colorScheme.onSurface
                        .withValues(alpha: .35),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        SellerAvatar(
          asset: seller.avatarAsset,
          name: seller.name,
          onPressed: onPressed,
        ),
      ],
    ),
  );
}
