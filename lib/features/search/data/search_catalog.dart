import 'package:hywork/core/localization/strings/search_strings.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

/// Published account-owned posts until a backend catalogue is connected.
abstract final class SearchCatalog {
  static String normalize(String value) {
    // Accept Persian/Arabic keyboard variants and Persian half-spaces.
    return value
        .toLowerCase()
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll(RegExp('[\u200c\u200f\u200e]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<PostItem> resultsFor(
    String city,
    String query, {
    Iterable<PostItem> publishedPosts = const [],
  }) {
    return _matchingPosts(publishedPosts, query).toList();
  }

  static Iterable<PostItem> _matchingPosts(
    Iterable<PostItem> posts,
    String query,
  ) {
    final words = normalize(query).split(' ');
    return posts.where((post) {
      if (!post.isPublished) return false;
      // Local posts have a free-form address, not a structured city field.
      // Keep them discoverable instead of assigning the demo catalogue's city.
      final text = normalize(
        '${post.title} ${SearchStrings.display(post.title)} ${SearchStrings.searchLabel(post.title)} '
        '${post.caption} ${post.category} ${post.details.tags.join(' ')}',
      );
      return words.every((word) => text.contains(word));
    });
  }

  static PostSeller? sellerFor(PostItem post) {
    final json = post.metadata['seller'];
    return json is Map
        ? PostSeller.fromJson(Map<String, dynamic>.from(json))
        : null;
  }
}
