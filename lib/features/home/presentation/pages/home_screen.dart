import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/home/presentation/widgets/common/home_feed_header.dart';
import 'package:nini/features/home/presentation/widgets/published/home_published_post_card.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/post_card_skeleton.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.active) {
      _started = true;
      context.read<FeedCubit?>()?.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _started = true;
      context.read<FeedCubit?>()?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = context.read<FeedCubit?>();
    if (feed != null) {
      return BlocBuilder<FeedCubit, BackendPostsState>(
        builder: (context, state) => RefreshIndicator(
          onRefresh: feed.refreshFromServer,
          child: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 500 &&
                  !state.error)
                feed.loadMore();
              return false;
            },
            child: _buildFeed(
              state.posts,
              isLoading: state.loading && state.posts.isEmpty,
              error: state.error,
              onRetry: state.page == 0 || state.failedRefresh
                  ? feed.refreshFromServer
                  : feed.loadMore,
            ),
          ),
        ),
      );
    }
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

  Widget _buildFeed(
    List<PostItem> posts, {
    bool isLoading = false,
    bool error = false,
    VoidCallback? onRetry,
  }) {
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
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: isLoading
              ? 4
              : posts.length + 1 + (error || posts.isEmpty ? 1 : 0),
          findChildIndexCallback: (key) => itemIndexes[key],
          itemBuilder: (context, index) {
            if (index == 0) {
              return const HomeFeedHeader();
            }

            if (isLoading) return const PostCardSkeleton();

            if (index > posts.length) {
              return Center(
                child: error
                    ? TextButton(
                        onPressed: onRetry,
                        child: const Text('Could not load posts. Retry'),
                      )
                    : const Text('No posts yet.'),
              );
            }

            final post = posts[index - 1];

            return HomePublishedPostCard(
              key: ValueKey('home-post-${post.id}'),
              post: post,
              active: widget.active,
              onProfilePressed: widget.onProfilePressed,
            );
          },
        ),
      ),
    );
  }
}
