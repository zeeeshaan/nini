import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

import '../seller_profile_actions/seller_profile_actions.dart';
import '../seller_post_grid/seller_post_grid.dart';
import '../seller_profile_header/seller_profile_header.dart';

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
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SellerProfileHeader(
          seller: seller,
          postCount: posts.length,
          category: posts.isEmpty
              ? ''
              : AppStrings.postCategory(posts.first.category),
        ),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SellerProfileActions(seller: seller),
      ),
      const SizedBox(height: 16),
      SellerPostGrid(posts: posts, onPostTap: onPostTap),
      const SizedBox(height: 24),
    ],
  );
}
