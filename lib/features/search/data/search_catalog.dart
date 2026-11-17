import 'package:nini/core/localization/strings/search_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

/// Published account-owned services until a backend service catalogue is connected.
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

  static bool _isGeneralQuery(String query) {
    const generalQueries = ['', 'لوله کش', 'لوله کشی', 'plumber', 'plumbing'];
    return generalQueries.contains(normalize(query));
  }

  static List<String> suggestionsFor(
    String query, {
    Iterable<PostItem> publishedPosts = const [],
  }) {
    final matches = <String>{
      for (final post in _matchingServices(publishedPosts, query)) post.title,
    };
    if (_isGeneralQuery(query)) {
      matches.addAll(SearchStrings.suggestions);
      return matches.toList();
    }
    final words = normalize(query).split(' ');
    for (final title in SearchStrings.suggestions) {
      final normalizedTitle = normalize(
        '$title ${SearchStrings.searchLabel(title)}',
      );
      if (words.every((word) => normalizedTitle.contains(word))) {
        matches.add(title);
      }
    }
    return matches.toList();
  }

  static List<PostItem> resultsFor(
    String city,
    String query, {
    Iterable<PostItem> publishedPosts = const [],
  }) {
    return _matchingServices(publishedPosts, query).toList();
  }

  static Iterable<PostItem> _matchingServices(
    Iterable<PostItem> posts,
    String query,
  ) {
    final words = normalize(query).split(' ');
    return posts.where((post) {
      if (!post.isPublished || !post.isService) return false;
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
