import 'package:nini/core/network/api_client.dart';
import 'package:nini/core/security/secure_token_store.dart';
import 'package:nini/features/posts/data/api_posts_repository.dart';
import 'package:nini/shared/models/post/post_item.dart';

import '../domain/public_user_profile.dart';

import 'package:nini/features/posts/domain/models/profile_category.dart';

class FollowPeoplePage {
  const FollowPeoplePage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });
  final List<
    ({PublicUserProfile profile, bool? verified, DateTime? followedAt})
  >
  items;
  final int total, page, limit;
}

class ApiPublicProfileRepository {
  ApiPublicProfileRepository(this._apiClient, this._tokenStore);
  final ApiClient _apiClient;
  final SecureTokenStore _tokenStore;

  Future<BackendPostsPage> loadPosts(
    String userId, {
    String? categoryId,
    int page = 1,
    int limit = 20,
  }) async {
    if (!ProfileCategory.isBackendId(userId) ||
        (categoryId != null && !ProfileCategory.isBackendId(categoryId)) ||
        page < 1 ||
        limit < 1 ||
        limit > 50) {
      throw const FormatException('Invalid profile posts request.');
    }
    final query = Uri(
      queryParameters: {
        'categoryId': ?categoryId,
        'page': '$page',
        'limit': '$limit',
      },
    ).query;
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    final response = await _apiClient.getPublic(
      'users/${Uri.encodeComponent(userId)}/posts?$query',
      token: token == null || token.isEmpty ? null : token,
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['items'] is! List ||
        data['total'] is! int ||
        (data['total'] as int) < 0 ||
        data['page'] != page ||
        data['limit'] != limit) {
      throw const FormatException('Invalid profile posts response.');
    }
    final items = <PostItem>[];
    for (final item in data['items'] as List) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid profile post.');
      }
      if (item['status'] != null && item['status'] != 'published') continue;
      final owner = item['owner'];
      if (owner is! Map || owner['id'] != userId) {
        throw const FormatException('Invalid post owner.');
      }
      items.add(backendPostFromJson(item));
    }
    return BackendPostsPage(
      items: List.unmodifiable(items),
      total: data['total'] as int,
      page: page,
      limit: limit,
    );
  }

  Future<FollowPeoplePage> loadFollowers(
    String userId, {
    int page = 1,
    int limit = 20,
  }) => _loadPeople(userId, 'followers', page: page, limit: limit);

  Future<FollowPeoplePage> loadFollowing(
    String userId, {
    int page = 1,
    int limit = 20,
  }) => _loadPeople(userId, 'following', page: page, limit: limit);

  Future<FollowPeoplePage> _loadPeople(
    String userId,
    String list, {
    required int page,
    required int limit,
  }) async {
    if (!ProfileCategory.isBackendId(userId) ||
        page < 1 ||
        limit < 1 ||
        limit > 50) {
      throw const FormatException('Invalid user or pagination.');
    }
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    final query = Uri(queryParameters: {'page': '$page', 'limit': '$limit'})
        .query;
    final response = await _apiClient.getPublic(
      'users/${Uri.encodeComponent(userId)}/$list?$query',
      token: token == null || token.isEmpty ? null : token,
    );
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['items'] is! List ||
        data['total'] is! int ||
        (data['total'] as int) < 0 ||
        data['page'] != page ||
        data['limit'] != limit) {
      throw const FormatException('Invalid people list response.');
    }
    final items =
        <({PublicUserProfile profile, bool? verified, DateTime? followedAt})>[];
    for (final value in data['items'] as List) {
      if (value is! Map<String, dynamic> ||
          value['id'] is! String ||
          !ProfileCategory.isBackendId(value['id'] as String) ||
          (value['username'] != null && value['username'] is! String) ||
          (value['verified'] != null && value['verified'] is! bool) ||
          (value['followedAt'] != null && value['followedAt'] is! String)) {
        throw const FormatException('Invalid person in list.');
      }
      final date = value['followedAt'] == null
          ? null
          : DateTime.tryParse(value['followedAt'] as String);
      if (value['followedAt'] != null && date == null) {
        throw const FormatException('Invalid follow date.');
      }
      items.add((
        profile: PublicUserProfile.fromJson(
          value,
          username: value['username'] as String? ?? '',
        ),
        verified: value['verified'] as bool?,
        followedAt: date,
      ));
    }
    return FollowPeoplePage(
      items: List.unmodifiable(items),
      total: data['total'] as int,
      page: data['page'] as int,
      limit: data['limit'] as int,
    );
  }

  Future<void> unfollow(
    PublicUserProfile profile, {
    required bool Function() isCurrentAccount,
  }) async {
    final id = profile.seller.id;
    if (!ProfileCategory.isBackendId(id) || !isCurrentAccount()) {
      throw const FormatException('Unfollow is unavailable for this profile.');
    }
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    if (!isCurrentAccount() ||
        token == null ||
        token.isEmpty ||
        token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('An authenticated session is required.');
    }
    final response = await _apiClient.delete(
      'users/${Uri.encodeComponent(id)}/follow',
      token: token,
    );
    if (!isCurrentAccount()) {
      throw const FormatException('The account changed.');
    }
    final data = response['data'];
    if (response['success'] != true ||
        data is! Map ||
        data['userId'] != id ||
        data['isFollowing'] != false) {
      throw const FormatException('Unfollow could not be confirmed.');
    }
  }

  Future<PublicUserProfile> follow(
    PublicUserProfile profile, {
    required bool Function() isCurrentAccount,
  }) async {
    final id = profile.seller.id;
    if (!ProfileCategory.isBackendId(id) || !isCurrentAccount()) {
      throw const FormatException('Follow is unavailable for this profile.');
    }
    final token = (await _tokenStore.getToken().timeout(
      const Duration(seconds: 10),
    ))?.trim();
    if (!isCurrentAccount() ||
        token == null ||
        token.isEmpty ||
        token.contains(RegExp(r'[\r\n]'))) {
      throw const FormatException('An authenticated session is required.');
    }
    final response = await _apiClient.post(
      'users/${Uri.encodeComponent(id)}/follow',
      token: token,
    );
    if (!isCurrentAccount()) {
      throw const FormatException('The account changed.');
    }
    final data = response['data'];
    if (response['success'] != true || data is! Map<String, dynamic>) {
      throw const FormatException('Follow could not be confirmed.');
    }
    final updated = PublicUserProfile.fromJson(
      data,
      username: profile.seller.username,
      expectedUserId: id,
    );
    if (updated.isFollowing != true || updated.isMe == true) {
      throw const FormatException('Follow could not be confirmed.');
    }
    return updated;
  }

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
