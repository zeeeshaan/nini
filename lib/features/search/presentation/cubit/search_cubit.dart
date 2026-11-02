import 'package:flutter_bloc/flutter_bloc.dart';

import 'search_state.dart';

export 'search_state.dart';

/// Owns only the search query, selected city, and visible panel.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit() : super(const SearchState());

  void editQuery(String query) {
    emit(state.copyWith(query: query, panel: SearchPanel.suggestions));
  }

  void showSuggestions() {
    emit(state.copyWith(panel: SearchPanel.suggestions));
  }

  void toggleCities() {
    if (state.panel == SearchPanel.cities) {
      closePanel();
      return;
    }
    emit(state.copyWith(panel: SearchPanel.cities));
  }

  void selectCity(String city) {
    emit(
      state.copyWith(
        city: city,
        query: state.submittedQuery,
        panel: SearchPanel.results,
      ),
    );
  }

  void submit(String query) {
    final submittedQuery = query.trim();
    emit(
      state.copyWith(
        query: submittedQuery,
        submittedQuery: submittedQuery,
        panel: SearchPanel.results,
      ),
    );
  }

  void closePanel() {
    emit(
      state.copyWith(query: state.submittedQuery, panel: SearchPanel.results),
    );
  }
}
