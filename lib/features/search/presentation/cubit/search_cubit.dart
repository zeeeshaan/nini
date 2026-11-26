import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hywork/features/posts/data/api_posts_repository.dart';

import 'search_state.dart';

export 'search_state.dart';

/// Owns only the search query, selected city, and visible panel.
class SearchCubit extends Cubit<SearchState> {
  SearchCubit([this.repository]) : super(const SearchState());
  final ApiPostsRepository? repository;
  int _suggestionRevision = 0;

  void editQuery(String query) {
    _suggestionRevision++;
    emit(
      state.copyWith(
        query: query,
        panel: SearchPanel.suggestions,
        suggestions: [],
        suggestionsLoading: false,
        suggestionsError: false,
      ),
    );
  }

  Future<void> loadSuggestions(String query) async {
    final repo = repository;
    if (repo == null ||
        query.trim().isEmpty ||
        state.query.trim() != query.trim()) {
      return;
    }
    final revision = ++_suggestionRevision;
    emit(state.copyWith(suggestionsLoading: true, suggestionsError: false));
    try {
      final terms = await repo.searchSuggestions(query.trim());
      if (!isClosed && revision == _suggestionRevision) {
        emit(state.copyWith(suggestions: terms, suggestionsLoading: false));
      }
    } catch (_) {
      if (!isClosed && revision == _suggestionRevision) {
        emit(
          state.copyWith(
            suggestions: [],
            suggestionsLoading: false,
            suggestionsError: true,
          ),
        );
      }
    }
  }

  void loadDiscovery() {
    if (repository == null) return;
    if (!state.popularLoaded && !state.popularLoading) _loadPopular();
    if (!state.trendingLoaded && !state.trendingLoading) _loadTrending();
  }

  Future<void> _loadPopular() async {
    emit(state.copyWith(popularLoading: true));
    try {
      final values = await repository!.popularSearches();
      if (!isClosed) {
        emit(
          state.copyWith(
            popular: values,
            popularLoading: false,
            popularLoaded: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(popularLoading: false));
    }
  }

  Future<void> _loadTrending() async {
    emit(state.copyWith(trendingLoading: true));
    try {
      final values = await repository!.trendingSearches();
      if (!isClosed) {
        emit(
          state.copyWith(
            trending: values,
            trendingLoading: false,
            trendingLoaded: true,
          ),
        );
      }
    } catch (_) {
      if (!isClosed) emit(state.copyWith(trendingLoading: false));
    }
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
    _suggestionRevision++;
    emit(
      state.copyWith(
        city: city,
        citySelected: true,
        query: state.submittedQuery,
        panel: SearchPanel.results,
      ),
    );
  }

  void submit(String query) {
    _suggestionRevision++;
    final submittedQuery = query.trim();
    emit(
      state.copyWith(
        query: submittedQuery,
        submittedQuery: submittedQuery,
        panel: SearchPanel.results,
        suggestions: const [],
        suggestionsLoading: false,
        suggestionsError: false,
      ),
    );
  }

  void closePanel() {
    _suggestionRevision++;
    emit(
      state.copyWith(query: state.submittedQuery, panel: SearchPanel.results),
    );
  }
}
