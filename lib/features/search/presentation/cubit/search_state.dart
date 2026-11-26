import 'package:hywork/core/localization/strings/search_strings.dart';

enum SearchPanel { results, cities, suggestions }

class SearchState {
  const SearchState({
    this.query = '',
    this.submittedQuery = '',
    this.city = SearchStrings.tehran,
    this.citySelected = false,
    this.panel = SearchPanel.results,
    this.suggestions = const [],
    this.popular = const [],
    this.trending = const [],
    this.suggestionsLoading = false,
    this.suggestionsError = false,
    this.popularLoading = false,
    this.trendingLoading = false,
    this.popularLoaded = false,
    this.trendingLoaded = false,
  });

  final String query;
  final String submittedQuery;
  final String city;
  final bool citySelected;
  final SearchPanel panel;
  final List<String> suggestions, popular, trending;
  final bool suggestionsLoading,
      suggestionsError,
      popularLoading,
      trendingLoading,
      popularLoaded,
      trendingLoaded;

  SearchState copyWith({
    String? query,
    String? submittedQuery,
    String? city,
    bool? citySelected,
    SearchPanel? panel,
    List<String>? suggestions,
    List<String>? popular,
    List<String>? trending,
    bool? suggestionsLoading,
    bool? suggestionsError,
    bool? popularLoading,
    bool? trendingLoading,
    bool? popularLoaded,
    bool? trendingLoaded,
  }) {
    return SearchState(
      query: query ?? this.query,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      city: city ?? this.city,
      citySelected: citySelected ?? this.citySelected,
      panel: panel ?? this.panel,
      suggestions: suggestions ?? this.suggestions,
      popular: popular ?? this.popular,
      trending: trending ?? this.trending,
      suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
      suggestionsError: suggestionsError ?? this.suggestionsError,
      popularLoading: popularLoading ?? this.popularLoading,
      trendingLoading: trendingLoading ?? this.trendingLoading,
      popularLoaded: popularLoaded ?? this.popularLoaded,
      trendingLoaded: trendingLoaded ?? this.trendingLoaded,
    );
  }
}
