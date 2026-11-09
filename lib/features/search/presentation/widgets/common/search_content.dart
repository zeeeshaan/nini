import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/posts/presentation/cubit/posts_cubit.dart';
import 'package:nini/features/home/presentation/helpers/home_post_navigation.dart';
import 'package:nini/features/home/presentation/helpers/published_home_navigation.dart';
import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/features/search/presentation/cubit/search_state.dart';

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
  });

  final SearchState state;
  final ValueChanged<String> onCitySelected;
  final ValueChanged<String> onQuerySelected;

  void _openPost(BuildContext context, PostItem post) {
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

    if (state.panel == SearchPanel.suggestions) {
      final suggestions = SearchCatalog.suggestionsFor(
        state.query,
        publishedPosts: publishedPosts,
      );
      if (suggestions.isEmpty) {
        return SearchEmptyState(onReset: () => onQuerySelected(''));
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
      return SearchEmptyState(onReset: () => onQuerySelected(''));
    }
    return SearchResultsGrid(
      key: ValueKey('${state.city}:${state.submittedQuery}'),
      posts: posts,
      onPostSelected: (post) => _openPost(context, post),
    );
  }
}
