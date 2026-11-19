import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/features/profile_settings/domain/user_profile.dart';
import 'package:nini/features/profile_settings/presentation/pages/profile_edit_screen.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/features/profile/presentation/widgets/categories/category_chips.dart';
import 'package:nini/features/profile/presentation/widgets/posts/profile_post_grid.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_avatar.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_header_actions.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_identity.dart';
import 'package:nini/features/profile/presentation/widgets/account/profile_stats.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/widgets/skeleton/profile_skeleton.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.onMessagesPressed, this.onMenuPressed});

  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMenuPressed;

  void _openPost(BuildContext context, PostItem post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PostDetailScreen(post: post, allowOwnerActions: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<UserProfileCubit?>()?.state;
    final profile = profileState?.profile ?? const UserProfile();
    final posts = context.watch<PostsCubit?>()?.state;
    final categories = context.watch<ProfileCategoriesCubit?>()?.state;
    final backendPosts = context.watch<OwnPostsCubit?>()?.state;
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: AppResponsiveBuilder(
        builder: (context, responsive) {
          final avatarSize = responsive.adaptive<double>(
            compact: 80,
            medium: 96,
            expanded: 104,
          );

          final maxWidth = responsive.adaptive<double>(
            compact: 600,
            medium: 600,
            expanded: 720,
          );

          if (profileState?.loading == true &&
              profile.displayName.isEmpty &&
              profile.username.isEmpty) {
            return SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalPadding,
                        ),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            ProfileHeaderActions(
                              onMessagesPressed: onMessagesPressed,
                              onMenuPressed: onMenuPressed,
                            ),
                            const SizedBox(height: 12),
                            const ProfileSkeleton(),
                            const SizedBox(height: 16),
                            const ProfileCategoryChips(),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                      ProfilePostGrid(
                        onPostTap: (post) => _openPost(context, post),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            );
          }

          return NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification.metrics.axis == Axis.vertical &&
                  notification.metrics.extentAfter < 600) {
                final backend = context.read<OwnPostsCubit?>();
                if (backend != null && !backend.state.error) backend.loadMore();
              }
              return false;
            },
            child: SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header and category section
                      // retain their horizontal padding.
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: responsive.horizontalPadding,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 16),

                            // Header actions
                            StaggeredEntrance(
                              child: ProfileHeaderActions(
                                onMessagesPressed: onMessagesPressed,
                                onMenuPressed: onMenuPressed,
                              ),
                            ),

                            const SizedBox(height: 12),

                            // Profile statistics and avatar
                            StaggeredEntrance(
                              index: 1,
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Expanded(
                                    child: ProfileStats(
                                      postCount:
                                          categories?.allCount?.toString() ??
                                          (backendPosts != null ||
                                                  posts == null ||
                                                  posts.isLoading ||
                                                  posts.loadFailed
                                              ? '—'
                                              : posts.posts.length.toString()),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: () => Navigator.of(context)
                                        .push<void>(
                                          MaterialPageRoute<void>(
                                            builder: (_) =>
                                                const ProfileEditScreen(),
                                          ),
                                        ),
                                    child: ProfileAvatar(
                                      size: avatarSize,
                                      asset: profile.avatarPath,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 8),

                            // Profile name, title and description
                            StaggeredEntrance(
                              index: 2,
                              child: ProfileIdentity(
                                name: profile.displayName.isEmpty
                                    ? profile.username
                                    : profile.displayName,
                                category: profile.businessType,
                                bio: profile.bio,
                                bioSpacing: 2,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Horizontal category chips
                            const StaggeredEntrance(
                              index: 3,
                              child: ProfileCategoryChips(),
                            ),

                            const SizedBox(height: 16),
                          ],
                        ),
                      ),

                      // Full-width posts grid.
                      // No horizontal padding.
                      ProfilePostGrid(
                        onPostTap: (post) {
                          _openPost(context, post);
                        },
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
