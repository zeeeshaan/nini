import 'package:flutter/material.dart';

import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/features/home/widgets/home_feed_header/home_feed_header.dart';
import 'package:hywork/features/home/widgets/home_published_post_card/home_published_post_card.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/skeleton/post_card_skeleton.dart';

class HomeFeedList extends StatelessWidget {
  const HomeFeedList({
    super.key,
    required this.posts,
    this.isLoading = false,
    this.error = false,
    this.active = true,
    this.onRetry,
    this.onProfilePressed,
  });

  final List<PostItem> posts;
  final bool isLoading;
  final bool error;
  final bool active;
  final VoidCallback? onRetry;
  final VoidCallback? onProfilePressed;

  @override
  Widget build(BuildContext context) {
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
          itemCount: _itemCount,
          findChildIndexCallback: (key) => itemIndexes[key],
          itemBuilder: (context, index) => _buildItem(index),
        ),
      ),
    );
  }

  int get _itemCount {
    if (isLoading) return 4;
    final showStatus = error || posts.isEmpty;
    return posts.length + 1 + (showStatus ? 1 : 0);
  }

  Widget _buildItem(int index) {
    if (index == 0) return const HomeFeedHeader();
    if (isLoading) return const PostCardSkeleton();
    if (index > posts.length) return _buildStatusFooter();

    final post = posts[index - 1];
    return HomePublishedPostCard(
      key: ValueKey('home-post-${post.id}'),
      post: post,
      active: active,
      onProfilePressed: onProfilePressed,
    );
  }

  Widget _buildStatusFooter() {
    return Center(
      child: error
          ? TextButton(
              onPressed: onRetry,
              child: const Text(HomeStrings.loadFailed),
            )
          : const Text(HomeStrings.empty),
    );
  }
}
