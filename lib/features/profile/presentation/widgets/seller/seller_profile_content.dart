import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import 'seller_profile_actions.dart';
import 'seller_post_grid.dart';
import 'seller_profile_header.dart';

class SellerProfileContent extends StatelessWidget {
  const SellerProfileContent({
    super.key,
    required this.seller,
    required this.posts,
    required this.onPostTap,
  });

  final PostSeller seller;
  final List<PostItem> posts;
  final ValueChanged<PostItem> onPostTap;

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
                seller: seller,
                postCount: posts.length,
                avatarSize: responsive.adaptive<double>(
                  compact: 104,
                  medium: 124,
                  expanded: 136,
                ),
                category: posts.isEmpty
                    ? ''
                    : AppStrings.postCategory(posts.first.category),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalPadding,
              ),
              child: SellerProfileActions(seller: seller),
            ),
            const SizedBox(height: 16),
            SellerPostGrid(posts: posts, onPostTap: onPostTap),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
