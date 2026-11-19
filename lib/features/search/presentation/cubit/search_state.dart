import 'package:nini/core/localization/strings/search_strings.dart';

enum SearchPanel { results, cities, suggestions }

class SearchState {
  const SearchState({
    this.query = '',
    this.submittedQuery = '',
    this.city = SearchStrings.tehran,
    this.citySelected = false,
    this.panel = SearchPanel.results,
  });

  final String query;
  final String submittedQuery;
  final String city;
  final bool citySelected;
  final SearchPanel panel;

  SearchState copyWith({
    String? query,
    String? submittedQuery,
    String? city,
    bool? citySelected,
    SearchPanel? panel,
  }) {
    return SearchState(
      query: query ?? this.query,
      submittedQuery: submittedQuery ?? this.submittedQuery,
      city: city ?? this.city,
      citySelected: citySelected ?? this.citySelected,
      panel: panel ?? this.panel,
    );
  }
}
