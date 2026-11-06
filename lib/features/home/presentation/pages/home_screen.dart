import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/home/presentation/widgets/home_feed_header/home_feed_header.dart';
import 'package:nini/features/home/presentation/widgets/home_product_card/home_product_card.dart';
import 'package:nini/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:nini/features/notifications/presentation/pages/notifications_screen.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../widgets/home_published_post_card/home_published_post_card.dart';

/// Published local posts followed by the existing sample feed.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onViewCart});

  final VoidCallback? onViewCart;

  // Google Pixel 9 Wintergreen, matching the phone in the reference.
  // Source: https://www.smarty.sk/google-pixel-9-12gb-128gb-wintergreen-4p159917
  static const phoneImageUrl =
      'https://doc.smarty.sk/pic/0f1e8c73d99d417ea73a3db313bcd924-600-600.webp';
  static const phoneTitle = 'Google Pixel 9\nWintergreen';

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _notifications = NotificationsCubit();
  @override
  void dispose() {
    _notifications.close();
    super.dispose();
  }

  void _openNotifications() {
    _notifications.search('');
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider.value(
          value: _notifications,
          child: const NotificationsScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final posts = context.read<PostsCubit?>();
    if (posts == null) return _feed(const []);
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: posts,
      buildWhen: (previous, current) => previous.posts != current.posts,
      builder: (_, state) =>
          _feed(state.posts.where((post) => post.isPublished).toList()),
    );
  }

  Widget _feed(List<PostItem> posts) {
    final indexes = <Key, int>{
      for (var index = 0; index < posts.length; index++)
        ValueKey('home-post-${posts[index].id}'): index + 1,
      for (var index = 1; index <= 6; index++)
        ValueKey('home_phone_$index'): posts.length + index,
    };
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: ListView.builder(
          key: const PageStorageKey('home_feed'),
          padding: EdgeInsets.zero,
          itemCount: posts.length + 7,
          findChildIndexCallback: (key) => indexes[key],
          itemBuilder: (context, index) {
            if (index == 0) {
              return BlocBuilder<NotificationsCubit, NotificationsState>(
                bloc: _notifications,
                builder: (_, state) => HomeFeedHeader(
                  unreadCount: state.unreadCount,
                  onNotificationsPressed: _openNotifications,
                ),
              );
            }
            if (index <= posts.length) {
              final post = posts[index - 1];
              return HomePublishedPostCard(
                key: ValueKey('home-post-${post.id}'),
                post: post,
              );
            }
            return HomeProductCard(
              key: ValueKey('home_phone_${index - posts.length}'),
              imageUrl: HomeScreen.phoneImageUrl,
              title: HomeScreen.phoneTitle,
              onViewCart: widget.onViewCart,
            );
          },
        ),
      ),
    );
  }
}
