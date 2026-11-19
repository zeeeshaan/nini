import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';
import 'package:nini/features/home/data/home_post_data.dart';
import 'package:nini/features/profile_settings/presentation/cubit/user_profile_cubit.dart';
import 'package:nini/features/search/presentation/cubit/search_state.dart';
import 'package:nini/features/posts/presentation/cubit/backend_posts_cubit.dart';

import 'package:nini/features/search/presentation/widgets/results/search_empty_state.dart';
import 'package:nini/features/search/presentation/widgets/common/search_city_list.dart';
import 'package:nini/features/search/presentation/widgets/results/search_results_grid.dart';
import 'package:nini/features/search/presentation/widgets/common/search_suggestions.dart';

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
    openHomePost(context, post, seller);
  }

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

    final backend = context.read<BackendPostsCubit?>();
    if (backend != null) {
      return BlocBuilder<BackendPostsCubit, BackendPostsState>(
        builder: (context, result) {
          final posts = result.posts;
          if (result.loading && result.posts.isEmpty)
            return const SearchResultsGrid(posts: [], isLoading: true);
          if (result.error && result.posts.isEmpty)
            return Center(
              child: TextButton(
                onPressed: backend.loadMore,
                child: const Text('Could not load search results. Retry'),
              ),
            );
          if (state.panel == SearchPanel.suggestions && posts.isNotEmpty) {
            return SearchSuggestions(
              suggestions: posts.map((post) => post.title).toSet().toList(),
              onSelected: onQuerySelected,
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

    if (state.panel == SearchPanel.suggestions) {
      final suggestions = SearchCatalog.suggestionsFor(
        state.query,
        publishedPosts: publishedPosts,
      );
      if (suggestions.isEmpty) {
        return SearchEmptyState(
          onReset: () => onQuerySelected(''),
          textAlign: emptyStateTextAlign,
        );
      }
      return SearchSuggestions(
        suggestions: suggestions,
        onSelected: onQuerySelected,
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
