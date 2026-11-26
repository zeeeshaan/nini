import 'package:flutter/material.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';

import '../../../domain/public_user_profile.dart';

import '../account/profile_avatar.dart';
import '../account/profile_identity.dart';
import '../account/profile_stats.dart';

class SellerProfileHeader extends StatelessWidget {
  const SellerProfileHeader({
    super.key,
    required this.profile,
    this.avatarSize = 104,
    this.postCount,
  });

  final PublicUserProfile profile;
  final double avatarSize;
  final int? postCount;

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
              postCount: (postCount ?? profile.postsCount)?.toString() ?? '—',
              salesCount: profile.followersCount?.toString() ?? '—',
              customerCount: profile.followingCount?.toString() ?? '—',
              salesLabel: ProfileScreenStrings.followers,
              customerLabel: ProfileScreenStrings.following,
            ),
          ),
          const SizedBox(width: 8),
          ProfileAvatar(size: avatarSize, asset: profile.seller.avatarAsset),
        ],
      ),
      const SizedBox(height: 8),
      ProfileIdentity(
        name: profile.seller.name.isEmpty
            ? profile.seller.username
            : profile.seller.name,
        category: '@${profile.seller.username}',
        bio: profile.seller.bio,
        location: profile.seller.location,
      ),
    ],
  );
}
