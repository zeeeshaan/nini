import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';

import '../../../domain/public_user_profile.dart';

import 'seller_profile_actions.dart';
import 'seller_post_grid.dart';
import 'seller_profile_header.dart';

class SellerProfileContent extends StatelessWidget {
  const SellerProfileContent({super.key, required this.profile});

  final PublicUserProfile profile;

  @override
  Widget build(BuildContext context) => AppResponsiveBuilder(
    builder: (context, responsive) => Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: responsive.adaptive<double>(
            compact: 600,
            medium: 600,
            expanded: 720,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                responsive.horizontalPadding,
                16,
                responsive.horizontalPadding,
                16,
              ),
              child: SellerProfileHeader(
                profile: profile,
                avatarSize: responsive.adaptive<double>(
                  compact: 104,
                  medium: 124,
                  expanded: 136,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: SellerProfileActions(
                seller: profile.seller,
                isFollowing: profile.isFollowing,
              ),
            ),
            const SizedBox(height: 16),
            SellerPostGrid(
              posts: const [],
              onPostTap: (_) {},
              emptyMessage: ProfilePostStrings.publicPostsUnavailable,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
