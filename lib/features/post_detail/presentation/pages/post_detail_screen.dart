import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/features/post_analytics/presentation/pages/post_analytics_screen.dart';
import 'package:nini/features/post_analytics/presentation/widgets/activity_tracking/post_activity_tracking.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/content/post_detail_body.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/helpers/manage_post_actions.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.galleryImages,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onMorePressed,
    this.onEditPressed,
  });

  final PostItem post;
  final List<String>? galleryImages;

  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onMorePressed;

  /// Supplied only for editable posts on the current user's profile.
  final ValueChanged<PostItem>? onEditPressed;

  @override
  Widget build(BuildContext context) {
    final posts = context.read<PostsCubit?>();
    if (posts == null) return _buildDetail(context, post);
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: posts,
      buildWhen: (previous, current) => previous.posts != current.posts,
      builder: (context, state) {
        final current =
            state.posts.where((item) => item.id == post.id).firstOrNull ?? post;
        return _buildDetail(context, current);
      },
    );
  }

  Widget _buildDetail(BuildContext context, PostItem post) {
    final images = galleryImages != null && galleryImages!.isNotEmpty
        ? galleryImages!
        : <String>[post.imageAsset];

    return BlocProvider(
      create: (_) => PostDetailCubit(),
      child: PostDetailActivityTracker(
        post: post,
        child: ScreenEntrance(
          child: Scaffold(
            appBar: AppBar(
              elevation: 0,
              toolbarHeight: 44,
              actions: [
                TextButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => PostAnalyticsScreen(post: post),
                    ),
                  ),
                  icon: const AppIcon(AppIcons.analytics, size: 17),
                  label: const Text(
                    AppStrings.viewAnalytics,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
              automaticallyImplyLeading: false,
              leadingWidth: 48,
              leading: StaggeredEntrance(
                distance: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const AppIcon(AppIcons.back, size: 18),
                  tooltip: AppStrings.back,
                ),
              ),
            ),

            body: PostDetailBody(
              post: post,
              images: images,
              onCommentsPressed: onCommentsPressed,
              onSharePressed: onSharePressed,
              onMorePressed:
                  context.read<PostsCubit?>()?.state.canManage(post) == true
                  ? () =>
                        managePostActions(context, post, onEdit: onEditPressed)
                  : onMorePressed,
            ),
          ),
        ),
      ),
    );
  }
}
