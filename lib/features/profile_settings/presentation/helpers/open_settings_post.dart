import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/pages/edit_post_screen.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

void openSettingsPost(
  BuildContext context,
  PostItem post, {
  bool edit = false,
}) {
  final current = context.read<PostsCubit>().state.find(post.id);
  if (current == null) {
    return;
  }
  if (edit) {
    Navigator.of(context).push<PostItem>(
      MaterialPageRoute(builder: (_) => EditPostScreen(post: current)),
    );
  } else {
    final seller = context.read<UserProfileCubit?>()?.seller;
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => PostDetailScreen(
          post: current,
          seller: seller,
          allowOwnerActions: true,
        ),
      ),
    );
  }
}
