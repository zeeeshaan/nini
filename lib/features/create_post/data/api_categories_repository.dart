import 'package:nini/core/network/api_client/api_client.dart';

import '../domain/models/post_category.dart';

class ApiCategoriesRepository {
  ApiCategoriesRepository(this._client);
  final ApiClient _client;

  Future<List<PostCategory>> load() async {
    // Public catalog: no account token or local fallback is needed.
    final response = await _client.getPublic('categories');
    final data = response['data'];
    if (response['success'] != true || data is! List) {
      throw const FormatException('Invalid categories response.');
    }
    final keys = <String>{};
    final categories = <PostCategory>[];
    for (final item in data) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid category response.');
      }
      final category = PostCategory.fromJson(item);
      if (!keys.add(category.key)) {
        throw const FormatException('Duplicate category key.');
      }
      categories.add(category);
    }
    return List.unmodifiable(categories);
  }
}
