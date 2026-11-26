import 'package:flutter/material.dart';
import 'package:hywork/core/theme/app_text_styles/app_text_styles.dart';
import 'package:hywork/features/cart/presentation/helpers/cart_format.dart';
import 'package:hywork/features/post_detail/presentation/helpers/post_cart_item.dart';
import 'package:hywork/features/posts/presentation/widgets/common/seller_avatar.dart';
import 'package:hywork/features/team/domain/team_provider_selection.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

class TeamPersonCard extends StatelessWidget {
  const TeamPersonCard({
    super.key,
    required this.person,
    required this.avatarSize,
    this.selection,
  });
  final PostSeller person;
  final TeamProviderSelection? selection;
  final double avatarSize;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final service = selection;
    final item = service == null
        ? null
        : postCartItem(service.post, seller: person);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SellerAvatar(
          asset: person.avatarAsset,
          name: person.name,
          size: avatarSize,
        ),
        const SizedBox(height: 10),
        Text(
          person.name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: AppTextStyles.bodyText,
          textDirection: TextDirection.ltr,
        ),
        Text(
          service?.post.title ?? 'Organizer',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.right,
          style: AppTextStyles.helper.copyWith(
            color: colors.onSurface.withValues(alpha: .55),
          ),
          textDirection: TextDirection.ltr,
        ),
        if (item != null) ...[
          const SizedBox(height: 6),
          Text(
            cartMoney((item.unitPrice - item.discountPerUnit) * 100),
            textAlign: TextAlign.right,
            style: AppTextStyles.pageTitleBold,
            textDirection: TextDirection.ltr,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              item.unit.label,
              textAlign: TextAlign.right,
              style: AppTextStyles.micro.copyWith(color: colors.onPrimary),
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ],
    );
  }
}
