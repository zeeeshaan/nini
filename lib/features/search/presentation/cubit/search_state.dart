import 'package:nini/core/localization/search_strings.dart';

enum SearchPanel { results, cities, suggestions }

class SearchState {
  const SearchState({
    this.query = '',
    this.submittedQuery = '',
    this.city = SearchStrings.tehran,
    this.panel = SearchPanel.results,
  });

  final String query;
  final String submittedQuery;
  final String city;
  final SearchPanel panel;

  SearchState copyWith({
    String? query,
    String? submittedQuery,
    String? city,
    SearchPanel? panel,
  }) {
    return SearchState(
      query: query ?? this.query,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      city: city ?? this.city,
      panel: panel ?? this.panel,
    );
  }
}
