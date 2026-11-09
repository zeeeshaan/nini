import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/home/presentation/widgets/common/home_feed_header.dart';
import 'package:nini/features/home/presentation/widgets/sample_product/home_product_card.dart';
import 'package:nini/features/home/presentation/widgets/published/home_published_post_card.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/features/notifications/presentation/helpers/open_notifications.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/post_card_skeleton.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onViewCart});

  final VoidCallback? onViewCart;

  static const int _samplePostCount = 6;

  static const phoneImageUrl =
      'https://doc.smarty.sk/pic/0f1e8c73d99d417ea73a3db313bcd924-600-600.webp';

  static const phoneTitle = 'Google Pixel 9\nWintergreen';

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
        final publishedProducts = state.posts
            .where((post) => post.isPublished && !post.isService)
            .toList();

        return _buildFeed(
          publishedProducts,
          isLoading: state.isLoading && state.posts.isEmpty,
        );
      },
    );
  }

  Widget _buildFeed(List<PostItem> posts, {bool isLoading = false}) {
    final itemIndexes = <Key, int>{
      for (var index = 0; index < posts.length; index++)
        ValueKey('home-post-${posts[index].id}'): index + 1,

      for (var index = 1; index <= _samplePostCount; index++)
        ValueKey('home_phone_$index'): posts.length + index,
    };

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          key: const PageStorageKey('home_feed'),
          padding: EdgeInsets.zero,
          itemCount: isLoading ? 4 : posts.length + _samplePostCount + 1,
          findChildIndexCallback: (key) => itemIndexes[key],
          itemBuilder: (context, index) {
            if (index == 0) {
              return BlocBuilder<NotificationsCubit, NotificationsState>(
                builder: (context, state) {
                  return HomeFeedHeader(
                    unreadCount: state.unreadCount,
                    onNotificationsPressed: () => openNotifications(context),
                  );
                },
              );
            }

            if (isLoading) return const PostCardSkeleton();

            if (index <= posts.length) {
              final post = posts[index - 1];

              return HomePublishedPostCard(
                key: ValueKey('home-post-${post.id}'),
                post: post,
              );
            }

            return HomeProductCard(
              key: ValueKey('home_phone_${index - posts.length}'),
              imageUrl: phoneImageUrl,
              title: phoneTitle,
              onViewCart: onViewCart,
            );
          },
        ),
      ),
    );
  }
}
