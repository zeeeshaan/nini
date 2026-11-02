import '../../domain/models/profile_category.dart';

class ProfileCategoriesState {
  const ProfileCategoriesState({
    this.categories = const [],
    this.selectedId,
    this.loading = true,
    this.saving = false,
    this.error,
    this.loadFailed = false,
  });
  final List<ProfileCategory> categories;
  final String? selectedId;
  final bool loading, saving, loadFailed;
  final String? error;
  ProfileCategory? find(String? id) {
    for (final category in categories) {
      if (category.id == id) return category;
    }
    return null;
  }
}
