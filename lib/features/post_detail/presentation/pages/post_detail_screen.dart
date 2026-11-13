import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/screen_entrance.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/features/post_analytics/presentation/pages/post_analytics_screen.dart';
import 'package:nini/features/post_analytics/presentation/widgets/metrics/post_activity_tracking.dart';
import 'package:nini/features/post_detail/presentation/cubit/post_detail_cubit.dart';
import 'package:nini/features/post_detail/presentation/widgets/common/post_detail_bottom_bar.dart';
import 'package:nini/features/post_detail/presentation/widgets/content/post_detail_body.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/post_likes_cubit.dart';
import 'package:nini/features/saved_posts/presentation/cubit/saved_posts_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/posts/presentation/helpers/manage_post_actions.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/comments_sheet.dart';
import 'package:nini/features/posts/presentation/widgets/interactions/share_sheet.dart';
import 'package:nini/features/profile/presentation/helpers/open_account_profile.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/chat/presentation/helpers/open_seller_conversation.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';

class PostDetailScreen extends StatelessWidget {
  const PostDetailScreen({
    super.key,
    required this.post,
    this.galleryImages,
    this.seller,
    this.onSellerPressed,
    this.onCommentsPressed,
    this.onSharePressed,
    this.onMorePressed,
    this.onEditPressed,
    this.allowOwnerActions = false,
    this.purchaseTrailing,
  });

  final PostItem post;
  final PostSeller? seller;
  final VoidCallback? onSellerPressed;
  final List<String>? galleryImages;

  final VoidCallback? onCommentsPressed;
  final VoidCallback? onSharePressed;
  final VoidCallback? onMorePressed;

  /// Supplied only for editable posts on the current user's profile.
  final ValueChanged<PostItem>? onEditPressed;

  /// Enabled only by the account Profile; ownership is checked separately.
  final bool allowOwnerActions;
  final Widget? purchaseTrailing;

  @override
  Widget build(BuildContext context) {
    final posts = context.read<PostsCubit?>();
    if (posts == null) return _buildDetail(context, post);
    return BlocBuilder<PostsCubit, PostsState>(
      bloc: posts,
      buildWhen: (previous, current) =>
          previous.posts != current.posts ||
          previous.isLoading != current.isLoading ||
          previous.loadFailed != current.loadFailed,
      builder: (context, state) {
        final current =
            state.posts.where((item) => item.id == post.id).firstOrNull ?? post;
        return _buildDetail(context, current);
      },
    );
  }

  Widget _buildDetail(BuildContext context, PostItem post) {
    final posts = context.read<PostsCubit?>()?.state;
    final isOwnPost = posts?.find(post.id) != null;
    final isOwnSeller = isOwnPost || seller?.id == localPostSeller.id;
    final author = isOwnSeller
        ? context.watch<UserProfileCubit?>()?.seller ?? localPostSeller
        : seller;
    final canManage = allowOwnerActions && posts?.canManage(post) == true;
    final canViewAnalytics = posts?.canViewAnalytics(post) == true;
    var openAuthorProfile = onSellerPressed;
    if (isOwnSeller && openAuthorProfile == null) {
      openAuthorProfile = allowOwnerActions
          ? () => Navigator.of(context).pop()
          : () => openAccountProfile(context);
    } else if (openAuthorProfile == null && author != null) {
      openAuthorProfile = () => openHomeSeller(context, post, author);
    }
    final images = galleryImages != null && galleryImages!.isNotEmpty
        ? galleryImages!
        : <String>[post.imageAsset];

    return BlocProvider(
      create: (context) => PostDetailCubit(
        postId: post.id,
        likes: context.read<PostLikesCubit?>(),
        savedPosts: context.read<SavedPostsCubit?>(),
      ),
      child: PostDetailActivityTracker(
        post: post,
        child: ScreenEntrance(
          child: Scaffold(
            extendBody: true,
            appBar: AppBar(
              elevation: 0,
              toolbarHeight: 44,
              actions: [
                if (canViewAnalytics)
                  TextButton.icon(
                    onPressed: () {
                      if (context.read<PostsCubit?>()?.state.canViewAnalytics(
                            post,
                          ) !=
                          true) {
                        return;
                      }
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => PostAnalyticsScreen(post: post),
                        ),
                      );
                    },
                    icon: const AppIcon(AppIcons.analytics, size: 17),
                    label: const Text(
                      AppStrings.viewAnalytics,
                      style: AppTextStyles.label,
                    ),
                  ),

                StaggeredEntrance(
                  distance: 8,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const AppIcon(AppIcons.backRight, size: 18),
                    tooltip: AppStrings.back,
                  ),
                ),
              ],
              automaticallyImplyLeading: false,
            ),

            bottomNavigationBar: PostDetailBottomBar(
              post: post,
              seller: author,
              trailing: post.isService ? purchaseTrailing : null,
            ),
            body: PostDetailBody(
              post: post,
              seller: author,
              onSellerPressed: openAuthorProfile,
              onMessagePressed: !isOwnSeller && author != null
                  ? () => openSellerConversation(context, author)
                  : null,
              images: images,
              onCommentsPressed:
                  onCommentsPressed ??
                  () => openPostCommentsSheet(context, postId: post.id),
              onSharePressed:
                  onSharePressed ??
                  () => openPostShareSheet(
                    context,
                    postId: post.id,
                    postText: [
                      post.title,
                      post.caption,
                    ].where((text) => text.trim().isNotEmpty).join('\n\n'),
                  ),
              onMorePressed: canManage
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
