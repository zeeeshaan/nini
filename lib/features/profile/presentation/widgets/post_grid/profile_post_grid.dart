import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/animation/staggered_entrance.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/profile_post_strings.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:nini/features/profile/presentation/widgets/profile_post_card/profile_post_card.dart';
import 'package:nini/shared/models/post/post_item.dart';

class ProfilePostGrid extends StatefulWidget {
  const ProfilePostGrid({super.key, required this.onPostTap});

  final ValueChanged<PostItem> onPostTap;

  @override
  State<ProfilePostGrid> createState() => _ProfilePostGridState();
}

class _ProfilePostGridState extends State<ProfilePostGrid> {
  final _gridKey = GlobalKey();
  String? _focusedPost;

  void _focusNewPost(PostsState state) {
    final id = state.lastPublished?.id;
    if (id == null || id == _focusedPost) return;
    _focusedPost = id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final context = _gridKey.currentContext;
      final target = context?.findRenderObject();
      if (context != null && target != null && target.attached) {
        Scrollable.maybeOf(context)?.position.ensureVisible(
          target,
          alignment: 0,
          duration: const Duration(milliseconds: 300),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<PostsCubit, PostsState>(
    builder: (context, state) {
      _focusNewPost(state);
      final categoryId = context
          .watch<ProfileCategoriesCubit>()
          .state
          .selectedId;
      final posts = state.posts
          .where(
            (post) =>
                categoryId == null || post.profileCategoryId == categoryId,
          )
          .toList();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.isLoading) const LinearProgressIndicator(minHeight: 2),
          if (state.loadFailed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Expanded(child: Text(AppStrings.savedPostsLoadFailed)),
                  TextButton(
                    onPressed: () => context.read<PostsCubit>().load(),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          if (!state.isLoading && posts.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                ProfilePostStrings.noPosts,
                textAlign: TextAlign.center,
              ),
            ),
          LayoutBuilder(
            key: _gridKey,
            builder: (context, constraints) {
              final width = constraints.maxWidth;

              // Keep 3 columns as in Figma on normal phones.
              // Use 2 only on exceptionally narrow displays.
              final columns = width < 330 ? 2 : 3;

              const spacing = 2.0;

              final cardWidth = (width - spacing * (columns - 1)) / columns;

              final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
              final detailsHeight =
                  (width < 400 ? 108.0 : 120.0) *
                  (textScale < 1 ? 1 : textScale);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                itemCount: posts.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  crossAxisSpacing: spacing,
                  mainAxisSpacing: 0,
                  mainAxisExtent: cardWidth + detailsHeight,
                ),
                itemBuilder: (context, index) {
                  final post = posts[index];

                  return StaggeredEntrance(
                    key: ValueKey(post.id),
                    index: 4 + index,
                    child: ProfilePostCard(
                      post: post,
                      detailsHeight: detailsHeight,
                      onTap: () => widget.onPostTap(post),
                    ),
                  );
                },
              );
            },
          ),
        ],
      );
    },
  );
}
