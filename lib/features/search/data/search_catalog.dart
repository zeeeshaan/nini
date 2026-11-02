import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/search_strings.dart';
import 'package:nini/shared/models/post/post_item.dart';

import 'demo_search_posts.dart';

/// Local preview content. A backend can supply listings later.
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

  static List<String> suggestionsFor(String query) {
    if (_isGeneralQuery(query)) return SearchStrings.suggestions;
    final words = normalize(query).split(' ');
    final matches = <String>[];
    for (final title in SearchStrings.suggestions) {
      final normalizedTitle = normalize(title);
      if (words.every((word) => normalizedTitle.contains(word))) {
        matches.add(title);
      }
    }
    return matches;
  }

  static List<PostItem> resultsFor(String city, String query) {
    final matchingTitles = suggestionsFor(query);
    final posts = <PostItem>[];
    for (final example in demoSearchPosts) {
      if (example.cities.contains(city) &&
          matchingTitles.contains(example.title)) {
        posts.add(_createPost(example, city));
      }
    }
    return posts;
  }

  // Only examples available in the selected city reach this conversion.
  static PostItem _createPost(DemoSearchPost example, String city) {
    return PostItem(
      id: 'search_${city}_${example.title}',
      imageAsset: example.imageAsset,
      title: example.title,
      category: SearchStrings.service,
      stockCount: 0,
      price: example.price,
      originalPrice: example.originalPrice,
      details: PostDetails(
        caption: '${example.title}، $city',
        tags: [
          city,
          SearchStrings.service,
          if (example.isPreOrder) AppStrings.preOrder,
        ],
        discount: example.discount,
        address: PostAddress(address: city, latitude: 0, longitude: 0),
      ),
    );
  }
}
