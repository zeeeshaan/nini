import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import '../account/profile_avatar.dart';
import '../account/profile_identity.dart';
import '../account/profile_stats.dart';

class SellerProfileHeader extends StatelessWidget {
  const SellerProfileHeader({
    super.key,
    required this.seller,
    required this.postCount,
    this.category = '',
    this.avatarSize = 104,
  });

  final PostSeller seller;
  final int postCount;
  final String category;
  final double avatarSize;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        textDirection: TextDirection.ltr,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: ProfileStats(
              postCount: AppStrings.persianDigits(postCount),
              salesCount: '—',
              customerCount: '—',
            ),
          ),
          const SizedBox(width: 8),
          ProfileAvatar(size: avatarSize, asset: seller.avatarAsset),
        ],
      ),
      const SizedBox(height: 8),
      ProfileIdentity(
        name: seller.name,
        category: category,
        bio: seller.bio,
        location: seller.location,
      ),
    ],
  );
}
