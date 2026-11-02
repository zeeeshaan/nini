import 'package:nini/features/posts/domain/models/profile_category.dart';

/// Replace the local adapter with an authenticated API adapter at composition.
/// Deletion removes only the tab, never posts or media. Missing category IDs on
/// posts are treated as unassigned by consumers and remain visible in All.
abstract class ProfileCategoriesRepository {
  Future<List<ProfileCategory>> load();
  Future<ProfileCategory> create(String name);
  Future<ProfileCategory> rename(String id, String name);
  Future<void> delete(String id);
}

class ProfileCategoryException implements Exception {
  const ProfileCategoryException(this.message);
  final String message;
}
