import 'package:flutter/material.dart';

import 'package:nini/features/search/data/search_catalog.dart';
import 'package:nini/features/search/presentation/cubit/search_state.dart';

import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_empty_state/search_empty_state.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_city_list/search_city_list.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_results_grid/search_results_grid.dart';
import 'package:nini/features/search/presentation/widgets/search_screen_widgets/search_suggestions/search_suggestions.dart';

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

  @override
  Widget build(BuildContext context) {
    if (state.panel == SearchPanel.cities) {
      return SearchCityList(
        selectedCity: state.city,
        onSelected: onCitySelected,
      );
    }

    if (state.panel == SearchPanel.suggestions) {
      final suggestions = SearchCatalog.suggestionsFor(state.query);
      if (suggestions.isEmpty) {
        return SearchEmptyState(onReset: () => onQuerySelected(''));
      }
      return SearchSuggestions(
        suggestions: suggestions,
        onSelected: onQuerySelected,
      );
    }

    final posts = SearchCatalog.resultsFor(state.city, state.submittedQuery);
    if (posts.isEmpty) {
      return SearchEmptyState(onReset: () => onQuerySelected(''));
    }
    return SearchResultsGrid(
      key: ValueKey('${state.city}:${state.submittedQuery}'),
      posts: posts,
    );
  }
}
