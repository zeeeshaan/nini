import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:hywork/features/search/data/search_catalog.dart';
import 'package:hywork/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:hywork/features/home/utils/home_post_navigation.dart';
import 'package:hywork/features/home/utils/published_home_navigation.dart';
import 'package:hywork/core/localization/strings/search_strings.dart';
import 'package:hywork/shared/widgets/app_toast/app_toast.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/features/home/data/home_post_data.dart';
import 'package:hywork/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:hywork/features/search/presentation/cubit/search_state.dart';
import 'package:hywork/features/posts/presentation/cubit/backend_posts_cubit.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';

import 'package:hywork/features/search/presentation/widgets/results/search_empty_state.dart';
import 'package:hywork/features/search/presentation/widgets/common/search_city_list.dart';
import 'package:hywork/features/search/presentation/widgets/results/search_results_grid.dart';
import 'package:hywork/features/search/presentation/widgets/common/search_suggestions.dart';

/// Shows results, the full city list, or suggestions below the fixed header.
class SearchContent extends StatelessWidget {
  const SearchContent({
    super.key,
    required this.state,
    required this.onCitySelected,
    required this.onQuerySelected,
    this.onPostSelected,
    this.emptyStateTextAlign = TextAlign.right,
  });

  final SearchState state;
  final TextAlign emptyStateTextAlign;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String> onQuerySelected;
  final void Function(PostItem post, PostSeller seller)? onPostSelected;

  void _openPost(BuildContext context, PostItem post) {
    if (onPostSelected != null) {
      final isLocalPost =
          context.read<PostsCubit?>()?.state.find(post.id) != null;
      final seller = isLocalPost
          ? context.read<UserProfileCubit?>()?.seller ?? localPostSeller
          : SearchCatalog.sellerFor(post);
      if (seller == null) {
        AppToast.warning(context, SearchStrings.providerUnavailable);
        return;
      }
      if (!isLocalPost) _logClick(context, post);
      onPostSelected!(post, seller);
      return;
    }
    if (context.read<PostsCubit?>()?.state.find(post.id) != null) {
      openPublishedHomePost(context, post);
      return;
    }
    final seller = SearchCatalog.sellerFor(post);
    if (seller == null) {
      AppToast.warning(context, SearchStrings.providerUnavailable);
      return;
    }
    _logClick(context, post);
    openHomePost(context, post, seller);
  }

  void _logClick(BuildContext context, PostItem post) {
    final result = context.read<BackendPostsCubit?>()?.state;
    final repository = context.read<ApiPostsRepository?>();
    final id = result?.searchId;
    final position = result?.searchPositions[post.id];
    if (id == null || position == null || repository == null) return;
    unawaited(
      repository
          .logSearchClick(searchId: id, postId: post.id, position: position)
          .catchError((_) {}),
    );
  }

  Widget _discovery(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (final section in [
        ('Popular searches', state.popular),
        ('Trending searches', state.trending),
      ])
        if (section.$2.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(section.$1, style: Theme.of(context).textTheme.labelLarge),
                SizedBox(
                  height: 40,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    reverse: true,
                    itemCount: section.$2.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => ActionChip(
                      label: Text(section.$2[index]),
                      onPressed: () => onQuerySelected(section.$2[index]),
                    ),
                  ),
                ),
              ],
            ),
          ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final postsState = context.watch<PostsCubit?>()?.state;
    final publishedPosts = postsState?.posts ?? const <PostItem>[];
    if (state.panel == SearchPanel.cities) {
      return SearchCityList(
        selectedCity: state.city,
        onSelected: onCitySelected,
      );
    }

    // Popular / trending only while the search field is focused.
    if (state.panel == SearchPanel.suggestions) {
      if (state.query.trim().isNotEmpty && state.suggestions.isNotEmpty) {
        return SearchSuggestions(
          suggestions: state.suggestions,
          onSelected: onQuerySelected,
        );
      }
      return ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [_discovery(context)],
      );
    }

    final backend = context.read<BackendPostsCubit?>();
    if (backend != null) {
      return BlocBuilder<BackendPostsCubit, BackendPostsState>(
        builder: (context, result) {
          final posts = result.posts;
          if (result.loading && result.posts.isEmpty) {
            return const SearchResultsGrid(posts: [], isLoading: true);
          }
          if (result.error && result.posts.isEmpty) {
            return Center(
              child: TextButton(
                onPressed: backend.loadMore,
                child: const Text('Could not load search results. Retry'),
              ),
            );
          }
          if (posts.isEmpty) {
            return Column(
              children: [
                Expanded(
                  child: SearchEmptyState(
                    onReset: () => onQuerySelected(''),
                    textAlign: emptyStateTextAlign,
                  ),
                ),
                if (result.hasMore)
                  TextButton(
                    onPressed: backend.loadMore,
                    child: const Text('More results'),
                  ),
              ],
            );
          }
          return Column(
            children: [
              if (result.error)
                TextButton(
                  onPressed: backend.loadMore,
                  child: const Text('Could not load more. Retry'),
                ),
              Expanded(
                child: SearchResultsGrid(
                  posts: posts,
                  onLoadMore: result.error ? null : backend.loadMore,
                  onPostSelected: (post) => _openPost(context, post),
                ),
              ),
            ],
          );
        },
      );
    }

    if (postsState?.isLoading == true && publishedPosts.isEmpty) {
      return const SearchResultsGrid(posts: [], isLoading: true);
    }

    final posts = SearchCatalog.resultsFor(
      state.city,
      state.submittedQuery,
      publishedPosts: publishedPosts,
    );
    if (posts.isEmpty) {
      return SearchEmptyState(
        onReset: () => onQuerySelected(''),
        textAlign: emptyStateTextAlign,
      );
    }
    return SearchResultsGrid(
      key: ValueKey('${state.city}:${state.submittedQuery}'),
      posts: posts,
      onPostSelected: (post) => _openPost(context, post),
    );
  }
}
