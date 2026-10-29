import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:visibility_detector/visibility_detector.dart';

import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/features/post_analytics/domain/models/post_analytics.dart';
import 'package:nini/features/post_analytics/presentation/cubit/post_analytics_cubit.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// A view is one opening of a published post. Watch time excludes covered routes
/// and background time, and segments share a session ID for accurate averages.
class PostDetailActivityTracker extends StatefulWidget {
  const PostDetailActivityTracker({
    super.key,
    required this.post,
    required this.child,
  });
  final PostItem post;
  final Widget child;
  @override
  State<PostDetailActivityTracker> createState() =>
      _PostDetailActivityTrackerState();
}

class _PostDetailActivityTrackerState extends State<PostDetailActivityTracker>
    with WidgetsBindingObserver, RouteAware {
  final _watch = Stopwatch();
  late final _session = 'detail_${DateTime.now().microsecondsSinceEpoch}';
  PostAnalyticsCubit? _analytics;
  PageRoute<dynamic>? _route;
  bool _recorded = false, _covered = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _analytics = context.read<PostAnalyticsCubit?>();
    final route = ModalRoute.of(context);
    if (route != _route) {
      entranceRouteObserver.unsubscribe(this);
      _route = route is PageRoute<dynamic> ? route : null;
      if (_route != null) entranceRouteObserver.subscribe(this, _route!);
    }
    if (!_recorded && widget.post.isPublished) {
      _recorded = true;
      _record(AnalyticsEventType.view, source: _session);
      _watch.start();
    }
  }

  void _record(
    AnalyticsEventType type, {
    double value = 1,
    String source = 'other',
  }) {
    if (widget.post.isPublished &&
        _analytics != null &&
        !_analytics!.isClosed) {
      unawaited(
        _analytics!.record(widget.post.id, type, value: value, source: source),
      );
    }
  }

  void _flush() {
    _watch.stop();
    final seconds = _watch.elapsedMicroseconds / Duration.microsecondsPerSecond;
    _watch.reset();
    if (seconds > 0) {
      _record(AnalyticsEventType.watch, value: seconds, source: _session);
    }
  }

  @override
  void didPushNext() {
    _covered = true;
    _flush();
  }

  @override
  void didPopNext() {
    _covered = false;
    if (widget.post.isPublished) _watch.start();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        !_covered &&
        widget.post.isPublished) {
      _watch.start();
    } else {
      _flush();
    }
  }

  @override
  void dispose() {
    _flush();
    entranceRouteObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<PostDetailCubit, PostDetailState>(
        listenWhen: (previous, current) =>
            previous.isLiked != current.isLiked ||
            previous.isBookmarked != current.isBookmarked,
        listener: (context, state) {
          // Count positive actions, rather than counting removal as another like/save.
          if (state.isLiked && !_liked) {
            _record(AnalyticsEventType.interaction, source: 'like');
          }
          if (state.isBookmarked && !_saved) {
            _record(AnalyticsEventType.interaction, source: 'save');
          }
          _liked = state.isLiked;
          _saved = state.isBookmarked;
        },
        child: widget.child,
      );
  bool _liked = false, _saved = false;
}

/// An impression occurs when at least half a home card becomes visible.
class PostImpressionTracker extends StatefulWidget {
  const PostImpressionTracker({
    super.key,
    required this.post,
    required this.child,
  });
  final PostItem post;
  final Widget child;
  @override
  State<PostImpressionTracker> createState() => _PostImpressionTrackerState();
}

class _PostImpressionTrackerState extends State<PostImpressionTracker> {
  bool _visible = false;
  @override
  Widget build(BuildContext context) {
    if (!widget.post.isPublished) return widget.child;
    return VisibilityDetector(
      key: ObjectKey(this),
      onVisibilityChanged: (info) {
        if (!mounted) return;
        if (info.visibleFraction < .1) {
          _visible = false;
          return;
        }
        if (info.visibleFraction < .5 ||
            _visible ||
            ModalRoute.of(context)?.isCurrent != true) {
          return;
        }
        _visible = true;
        final analytics = context.read<PostAnalyticsCubit?>();
        if (analytics != null && !analytics.isClosed) {
          unawaited(
            analytics.record(
              widget.post.id,
              AnalyticsEventType.impression,
              source: 'home',
            ),
          );
        }
      },
      child: widget.child,
    );
  }
}
