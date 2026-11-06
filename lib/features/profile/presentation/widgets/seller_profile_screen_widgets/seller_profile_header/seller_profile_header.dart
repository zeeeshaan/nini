import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/posts/presentation/widgets/seller_avatar/seller_avatar.dart';
import 'package:nini/shared/models/post/post_seller.dart';

class SellerProfileHeader extends StatelessWidget {
  const SellerProfileHeader({
    super.key,
    required this.seller,
    required this.postCount,
    this.category = '',
  });

  final PostSeller seller;
  final int postCount;
  final String category;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          SellerAvatar(asset: seller.avatarAsset, name: seller.name, size: 88),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  seller.name,
                  textAlign: TextAlign.left,
                  style: AppTextStyles.profileName,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _ProfileStat(
                        value: AppStrings.persianDigits(postCount),
                        label: AppStrings.posts,
                      ),
                    ),
                    const Expanded(
                      child: _ProfileStat(
                        value: '—',
                        label: AppStrings.followers,
                      ),
                    ),
                    const Expanded(
                      child: _ProfileStat(
                        value: '—',
                        label: AppStrings.following,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      if (category.isNotEmpty) ...[
        const SizedBox(height: 12),
        Text(
          category,
          textAlign: TextAlign.left,
          style: AppTextStyles.category.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .5),
          ),
        ),
      ],
      if (seller.bio.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(seller.bio, textAlign: TextAlign.left, style: AppTextStyles.bio),
      ],
      if (seller.location.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          seller.location,
          textAlign: TextAlign.left,
          style: AppTextStyles.caption.copyWith(
            color: Theme.of(context).colorScheme.onSurface
                .withValues(alpha: .6),
          ),
        ),
      ],
    ],
  );
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(value, textAlign: TextAlign.left, style: AppTextStyles.statNumber),
      const SizedBox(height: 2),
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.left,
        style: AppTextStyles.statLabel,
      ),
    ],
  );
}
