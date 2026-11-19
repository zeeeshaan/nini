import '../../domain/models/profile_category.dart';

class ProfileCategoriesState {
  const ProfileCategoriesState({
    this.categories = const [],
    this.selectedId,
    this.loading = true,
    this.saving = false,
    this.error,
    this.loadFailed = false,
    this.allCount,
    this.uncategorizedCount,
  });
  final List<ProfileCategory> categories;
  final String? selectedId;
  final bool loading, saving, loadFailed;
  final String? error;
  final int? allCount, uncategorizedCount;

  ProfileCategoriesState copyWith({
    List<ProfileCategory>? categories,
    String? selectedId,
    bool clearSelection = false,
    bool? loading,
    bool? saving,
    bool? loadFailed,
    String? error,
    bool clearError = false,
  }) => ProfileCategoriesState(
    categories: categories ?? this.categories,
    selectedId: clearSelection ? null : selectedId ?? this.selectedId,
    loading: loading ?? this.loading,
    saving: saving ?? this.saving,
    loadFailed: loadFailed ?? this.loadFailed,
    error: clearError ? null : error ?? this.error,
    allCount: allCount,
    uncategorizedCount: uncategorizedCount,
  );
  ProfileCategory? find(String? id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
