import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nini/core/localization/strings/profile_post_strings.dart';
import 'package:nini/features/posts/domain/models/profile_category.dart';
import 'package:nini/features/posts/domain/profile_categories_repository.dart';

import 'profile_categories_state.dart';

export 'profile_categories_state.dart';

/// Shared by the profile, tab manager, and create/edit category selectors.
class ProfileCategoriesCubit extends Cubit<ProfileCategoriesState> {
  ProfileCategoriesCubit(this.repository)
    : super(const ProfileCategoriesState());
  final ProfileCategoriesRepository repository;

  Future<void>? _loading;
  Future<void> load() => state.saving
      ? Future.value()
      : _loading ??= _load().whenComplete(() => _loading = null);

  void clearError() {
    if (state.error == null || state.loadFailed) return;
    emit(
      ProfileCategoriesState(
        categories: state.categories,
        selectedId: state.selectedId,
        loading: state.loading,
        saving: state.saving,
      ),
    );
  }

  Future<void> _load() async {
    if (state.saving) return;
    emit(
      ProfileCategoriesState(
        categories: state.categories,
        selectedId: state.selectedId,
      ),
    );
    try {
      final categories = await repository.load();
      if (isClosed) return;
      emit(
        ProfileCategoriesState(
          categories: List.unmodifiable(categories),
          loading: false,
          selectedId: categories.any((item) => item.id == state.selectedId)
              ? state.selectedId
              : null,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          ProfileCategoriesState(
            categories: state.categories,
            selectedId: state.selectedId,
            loading: false,
            loadFailed: true,
            error: ProfilePostStrings.loadFailed,
          ),
        );
      }
    }
  }

  void select(String? id) {
    if (id != null && state.find(id) == null) return;
    emit(
      ProfileCategoriesState(
        categories: state.categories,
        selectedId: id,
        loading: state.loading,
        saving: state.saving,
        loadFailed: state.loadFailed,
        error: state.error,
      ),
    );
  }

  Future<bool> create(String name) => _mutate(() async {
    final category = await repository.create(name);
    return [...state.categories, category];
  });
  Future<bool> rename(String id, String name) => _mutate(() async {
    final category = await repository.rename(id, name);
    return [
      for (final item in state.categories)
        if (item.id == id) category else item,
    ];
  });
  Future<bool> delete(String id) => _mutate(() async {
    await repository.delete(id);
    return state.categories.where((item) => item.id != id).toList();
  });

  Future<bool> _mutate(
    Future<List<ProfileCategory>> Function() operation,
  ) async {
    if (state.loading || state.saving || state.loadFailed) return false;
    emit(
      ProfileCategoriesState(
        categories: state.categories,
        selectedId: state.selectedId,
        loading: false,
        saving: true,
      ),
    );
    try {
      final categories = await operation();
      if (isClosed) return false;
      emit(
        ProfileCategoriesState(
          categories: List.unmodifiable(categories),
          loading: false,
          selectedId: categories.any((item) => item.id == state.selectedId)
              ? state.selectedId
              : null,
        ),
      );
      return true;
    } catch (error) {
      if (!isClosed) {
        emit(
          ProfileCategoriesState(
            categories: state.categories,
            selectedId: state.selectedId,
            loading: false,
            error: error is ProfileCategoryException
                ? error.message
                : ProfilePostStrings.saveFailed,
          ),
        );
      }
      return false;
    }
  }
}
