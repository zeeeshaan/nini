import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/home/widgets/home_feed_list/home_feed_list.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, this.onProfilePressed, this.active = true});

  final VoidCallback? onProfilePressed;
  final bool active;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _started = false;

  FeedCubit get _feed => context.read<FeedCubit>();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started && widget.active) {
      _started = true;
      _feed.refresh();
    }
  }

  @override
  void didUpdateWidget(covariant HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _started = true;
      _feed.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;

    return BlocBuilder<FeedCubit, BackendPostsState>(
      builder: (context, state) => RefreshIndicator(
        onRefresh: feed.refreshFromServer,
        child: NotificationListener<ScrollNotification>(
          onNotification: (notification) {
            if (notification.metrics.axis == Axis.vertical &&
                notification.metrics.extentAfter < 500 &&
                !state.error) {
              feed.loadMore();
            }
            return false;
          },
          child: HomeFeedList(
            posts: state.posts,
            isLoading: state.loading && state.posts.isEmpty,
            error: state.error,
            active: widget.active,
            onProfilePressed: widget.onProfilePressed,
            onRetry: state.page == 0 || state.failedRefresh
                ? feed.refreshFromServer
                : feed.loadMore,
          ),
        ),
      ),
    );
  }
}
