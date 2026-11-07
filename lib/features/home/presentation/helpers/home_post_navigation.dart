import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/profile/presentation/helpers/open_account_profile.dart';
import 'package:nini/features/profile/presentation/page/seller_profile_screen/seller_profile_screen.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

void openHomePost(BuildContext context, PostItem post, PostSeller seller) {
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => PostDetailScreen(
        post: post,
        seller: seller,
        onSellerPressed: () => openHomeSeller(context, post, seller),
      ),
    ),
  );
}

void openHomeSeller(BuildContext context, PostItem post, PostSeller seller) {
  if (seller.id == localPostSeller.id ||
      context.read<PostsCubit?>()?.state.find(post.id) != null) {
    openAccountProfile(context);
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SellerProfileScreen(
        seller: seller,
        posts: [post],
        onPostTap: (selected) => openHomePost(context, selected, seller),
      ),
    ),
  );
}
