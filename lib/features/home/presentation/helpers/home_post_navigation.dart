import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/shared/models/local_identity.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/login/presentation/cubit/session_cubit.dart';
import 'package:nini/features/profile/presentation/helpers/open_account_profile.dart';
import 'package:nini/features/profile/presentation/pages/seller_profile_screen.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

void openHomePost(
  BuildContext context,
  PostItem post,
  PostSeller seller, {
  VoidCallback? onOwnProfilePressed,
}) {
  final openOwn =
      onOwnProfilePressed ?? AccountProfileNavigation.maybeOf(context);
  final sourceRoute = ModalRoute.of(context);
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (detailContext) => PostDetailScreen(
        post: post,
        seller: seller,
        onSellerPressed: () => openHomeSeller(
          detailContext,
          post,
          seller,
          onOwnProfilePressed: () {
            if (!context.mounted) return;
            if (sourceRoute != null) {
              Navigator.of(context).popUntil((route) => route == sourceRoute);
            }
            if (openOwn != null) {
              openOwn();
            } else {
              openAccountProfile(context);
            }
          },
        ),
      ),
    ),
  );
}

bool isAccountPostSeller(
  BuildContext context,
  PostItem post,
  PostSeller seller,
) {
  final session = context.read<SessionCubit?>()?.state;
  final accountId = session == null
      ? context.read<UserProfileCubit?>()?.state.profile.id
      : session.status == SessionStatus.authenticated
      ? session.userId
      : null;
  if (accountId != null && accountId.isNotEmpty && seller.id == accountId) {
    return true;
  }
  final ownPost = context.read<PostsCubit?>()?.state.find(post.id) != null;
  return ownPost &&
      (seller.id.isEmpty ||
          seller.id == localProfileId ||
          accountId == null ||
          accountId.isEmpty);
}

void openHomeSeller(
  BuildContext context,
  PostItem post,
  PostSeller seller, {
  VoidCallback? onOwnProfilePressed,
}) {
  final action =
      onOwnProfilePressed ?? AccountProfileNavigation.maybeOf(context);
  final sourceRoute = ModalRoute.of(context);
  void openOwn() {
    if (!context.mounted) return;
    if (sourceRoute != null) {
      Navigator.of(context).popUntil((route) => route == sourceRoute);
    }
    if (action != null) {
      action();
    } else {
      openAccountProfile(context);
    }
  }

  if (isAccountPostSeller(context, post, seller)) {
    openOwn();
    return;
  }
  Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => SellerProfileScreen(
        username: seller.username,
        expectedUserId: seller.id.isEmpty ? null : seller.id,
        onOwnProfilePressed: openOwn,
      ),
    ),
  );
}
