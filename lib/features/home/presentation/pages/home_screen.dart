import 'package:flutter/material.dart';

import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:nini/features/home/presentation/widgets/category_chips/category_chips.dart';
import 'package:nini/features/home/presentation/widgets/home_header_actions/home_header_actions.dart';
import 'package:nini/features/home/presentation/widgets/home_profile_status/home_profile_status.dart';
import 'package:nini/features/home/presentation/widgets/post_grid/home_post_grid.dart';
import 'package:nini/features/home/presentation/widgets/profile_avatar/profile_avatar.dart';
import 'package:nini/features/home/presentation/widgets/profile_identity/profile_identity.dart';
import 'package:nini/features/post_detail/presentation/pages/post_detail_screen.dart';
import 'package:nini/shared/models/post/post_item.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, this.onMessagesPressed, this.onMenuPressed});

  final VoidCallback? onMessagesPressed;
  final VoidCallback? onMenuPressed;

  void _openPost(BuildContext context, PostItem post) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => PostDetailScreen(post: post)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface,
      child: AppResponsiveBuilder(
        builder: (context, responsive) {
          final avatarSize = responsive.adaptive<double>(
            compact: 104,
            medium: 124,
            expanded: 136,
          );

          final maxWidth = responsive.adaptive<double>(
            compact: 600,
            medium: 600,
            expanded: 720,
          );

          return SingleChildScrollView(
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
                            child: HomeHeaderActions(
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
                                  child: HomeProfileStats(
                                    responsive: responsive,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                HomeProfileAvatar(size: avatarSize),
                              ],
                            ),
                          ),

                          const SizedBox(height: 8),

                          // Profile name, title and description
                          StaggeredEntrance(
                            index: 2,
                            child: HomeProfileIdentity(responsive: responsive),
                          ),

                          const SizedBox(height: 16),

                          // Horizontal category chips
                          const StaggeredEntrance(
                            index: 3,
                            child: HomeCategoryChips(),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),

                    // Full-width posts grid.
                    // No horizontal padding.
                    HomePostGrid(
                      onPostTap: (post) {
                        _openPost(context, post);
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
