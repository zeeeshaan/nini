import 'package:nini/features/posts/domain/models/profile_category.dart';

/// Deletion removes only the tab, never posts or media. Missing category IDs on
/// posts are treated as unassigned by consumers and remain visible in All.
abstract class ProfileCategoriesRepository {
  Future<ProfileCategoryList> load();
  Future<ProfileCategory> create(String name);
  Future<ProfileCategory> rename(String id, String name);
  Future<int?> delete(String id);
  Future<ProfileCategoryList> reorder(List<String> ids);
}

class ProfileCategoryException implements Exception {
  const ProfileCategoryException(this.message, {this.sessionExpired = false});
  final String message;
  final bool sessionExpired;
}
