import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';

import '../domain/public_user_profile.dart';

import 'package:nini/features/posts/domain/models/profile_category.dart';

class ApiPublicProfileRepository {
  ApiPublicProfileRepository(this._apiClient, this._tokenStore);
  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  Future<ProfileCategoryList> loadCategories(String userId) async {
    if (!ProfileCategory.isBackendId(userId)) {
      throw const FormatException('A backend user UUID is required.');
    }
    final response = await _apiClient.getPublic(
      'users/${Uri.encodeComponent(userId)}/categories',
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid public categories response.');
    }
    return ProfileCategoryList.fromApiJson(data);
  }

  Future<PublicUserProfile> load(String value, {String? expectedUserId}) async {
    final username = PublicUserProfile.normalizeUsername(value);
    if (username == null) {
      throw const FormatException('A backend username is required.');
    }
    final stored = await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    );
    final token = stored?.trim();
    final response = await _apiClient.getPublic(
      'users/profile/${Uri.encodeComponent(username)}',
      token: token == null || token.isEmpty ? null : token,
    );
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Invalid public profile response.');
    }
    return PublicUserProfile.fromJson(
      data,
      username: username,
      expectedUserId: expectedUserId,
    );
  }
}
