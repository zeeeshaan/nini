import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/core/animations/staggered_animation/staggered_animation.dart';
import 'package:hywork/core/localization/strings/profile_post_strings.dart';
import 'package:hywork/core/localization/strings/profile_screen_strings.dart';
import 'package:hywork/core/responsiveness/app_responsiveness/app_responsiveness.dart';
import 'package:hywork/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/features/posts/presentation/cubit/profile_categories_cubit.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';
import 'package:hywork/features/posts/domain/models/profile_category.dart';
import 'package:hywork/features/profile/presentation/widgets/posts/profile_post_card.dart';

import 'profile_posts_empty_state.dart';

import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/widgets/skeleton/product_card_skeleton.dart';
import 'package:hywork/shared/widgets/skeleton/app_shimmer.dart';

class ProfilePostGrid extends StatefulWidget {
  const ProfilePostGrid({super.key, required this.onPostTap});

  final ValueChanged<PostItem> onPostTap;

  @override
  State<ProfilePostGrid> createState() => _ProfilePostGridState();
}

class _ProfilePostGridState extends State<ProfilePostGrid> {
  final _gridKey = GlobalKey();
  String? _focusedPost;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final backend = context.read<OwnPostsCubit?>();
        final selected = context
            .read<ProfileCategoriesCubit>()
            .state
            .selectedId;
        if (backend != null &&
            backend.hasRequestedCategory &&
            backend.requestedCategoryId == selected &&
            (backend.state.loading || backend.state.page > 0)) {
          return;
        }
        _refreshCategory(selected);
      });
    }
  }

  void _refreshCategory(String? id) {
    final backend = context.read<OwnPostsCubit?>();
    final repository = context.read<ApiPostsRepository?>();
    if (backend == null || repository == null) return;
    backend.requestedCategoryId = id;
    backend.hasRequestedCategory = true;
    if (id != null && !ProfileCategory.isBackendId(id)) {
      backend.refresh(
        load: (_) async =>
            const BackendPostsPage(items: [], total: 0, page: 1, limit: 20),
      );
      return;
    }
    backend.refresh(
      load: (page) =>
          repository.loadOwnProfilePosts(page: page, categoryId: id),
    );
  }

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
  Widget build(BuildContext context) {
    final backend = context.read<OwnPostsCubit?>();
    if (backend != null) {
      return BlocListener<ProfileCategoriesCubit, ProfileCategoriesState>(
        listenWhen: (previous, current) =>
            previous.selectedId != current.selectedId,
        listener: (_, state) => _refreshCategory(state.selectedId),
        child: BlocBuilder<OwnPostsCubit, BackendPostsState>(
          builder: (context, state) => _buildGrid(
            context,
            PostsState(
              posts: state.posts,
              isLoading: state.loading,
              loadFailed: state.error,
            ),
            backend,
          ),
        ),
      );
    }
    return BlocBuilder<PostsCubit, PostsState>(
      builder: (context, state) => _buildGrid(context, state, null),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    PostsState state,
    OwnPostsCubit? backend,
  ) {
    _focusNewPost(state);
    final categoryId = context.watch<ProfileCategoriesCubit>().state.selectedId;
    final posts = state.posts
        .where(
          (post) => categoryId == null || post.profileCategoryId == categoryId,
        )
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (state.isLoading && state.posts.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        if (state.loadFailed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    ProfileScreenStrings.savedPostsLoadFailed,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.ltr,
                  ),
                ),
                TextButton(
                  onPressed: () => backend == null
                      ? context.read<PostsCubit>().load()
                      : backend.loadMore(),
                  child: const Text(
                    ProfileScreenStrings.retry,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        if (!state.isLoading && !state.loadFailed && state.posts.isEmpty)
          const ProfilePostsEmptyState()
        else if (!state.isLoading && !state.loadFailed && posts.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              ProfilePostStrings.noPosts,
              textAlign: TextAlign.right,
              textDirection: TextDirection.ltr,
            ),
          ),
        AppResponsiveBuilder(
          key: _gridKey,
          builder: (context, responsive) {
            final width = responsive.width;

            // Keep 3 columns as in Figma on normal phones.
            // Use 2 only on exceptionally narrow displays.
            final textScale = (MediaQuery.textScalerOf(context).scale(14) / 14)
                .clamp(1.0, double.infinity);
            final maxColumns = responsive.gridColumns.clamp(1, 3);
            final columns = (width / (110 * textScale)).floor().clamp(
              1,
              maxColumns,
            );

            const spacing = 2.0;

            final cardWidth = (width - spacing * (columns - 1)) / columns;

            final contentScale = cardWidth / ProfilePostCard.referenceWidth;
            final detailsHeight = ProfilePostCard.detailsHeightFor(
              context,
              contentScale,
            );

            return Directionality(
              textDirection: TextDirection.rtl,
              child: AppShimmer.when(
                enabled: state.isLoading && state.posts.isEmpty,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: state.isLoading && state.posts.isEmpty
                      ? columns * 2
                      : posts.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    crossAxisSpacing: spacing,
                    mainAxisSpacing: 0,
                    mainAxisExtent: cardWidth + detailsHeight,
                  ),
                  itemBuilder: (_, index) {
                    if (state.isLoading && state.posts.isEmpty) {
                      return const ProductCardSkeleton(animated: false);
                    }
                    final post = posts[index];

                    return StaggeredEntrance(
                      key: ValueKey(post.id),
                      index: 4 + index,
                      child: Directionality(
                        textDirection: Directionality.of(context),
                        child: ProfilePostCard(
                          post: post,
                          showStock: !post.isService,
                          detailsHeight: detailsHeight,
                          contentScale: contentScale,
                          onTap: () => widget.onPostTap(post),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
