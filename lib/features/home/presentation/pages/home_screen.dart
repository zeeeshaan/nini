import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/home/presentation/widgets/common/home_feed_header.dart';
import 'package:nini/features/home/presentation/widgets/published/home_published_post_card.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/post_card_skeleton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    this.onViewCart,
    this.onProfilePressed,
    this.active = true,
  });

  final VoidCallback? onViewCart;
  final VoidCallback? onProfilePressed;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final postsCubit = context.read<PostsCubit?>();

    if (postsCubit == null) {
      return _buildFeed(const []);
    }

    return BlocBuilder<PostsCubit, PostsState>(
      bloc: postsCubit,
      buildWhen: (previous, current) =>
          previous.posts != current.posts ||
          previous.isLoading != current.isLoading,
      builder: (context, state) {
        final publishedPosts = state.posts
            .where((post) => post.isPublished)
            .toList();

        return _buildFeed(
          publishedPosts,
          isLoading: state.isLoading && state.posts.isEmpty,
        );
      },
    );
  }

  Widget _buildFeed(List<PostItem> posts, {bool isLoading = false}) {
    final itemIndexes = <Key, int>{
      for (var index = 0; index < posts.length; index++)
        ValueKey('home-post-${posts[index].id}'): index + 1,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          key: const PageStorageKey('home_feed'),
          padding: EdgeInsets.zero,
          itemCount: isLoading ? 4 : posts.length + 1,
          findChildIndexCallback: (key) => itemIndexes[key],
          itemBuilder: (context, index) {
            if (index == 0) {
              return const HomeFeedHeader();
            }

            if (isLoading) return const PostCardSkeleton();

            final post = posts[index - 1];

            return HomePublishedPostCard(
              key: ValueKey('home-post-${post.id}'),
              post: post,
              active: active,
              onProfilePressed: onProfilePressed,
            );
          },
        ),
      ),
    );
  }
}
