import 'package:flutter/foundation.dart';

import 'package:nini/shared/models/post/post_details.dart';
import 'package:nini/shared/models/post/post_media.dart';

export 'package:nini/shared/models/post/post_details.dart';
export 'package:nini/shared/models/post/post_media.dart';

@immutable
class PostItem {
  const PostItem({
    required this.id,
    required this.imageAsset,
    required this.title,
    required this.category,
    required this.stockCount,
    required this.price,
    required this.originalPrice,
    this.media = const [],
    this._metadata = const {},
    this._details,
    this.publishedAt,
    this.profileCategoryId,
  });
  final String id, imageAsset, title, category, price, originalPrice;
  final int stockCount;

  /// User-managed profile tab, independent of the Product/Service type.
  /// Null or a deleted tab ID is shown only under All.
  final String? profileCategoryId;
  final List<PostMedia> media;
  final Map<String, dynamic> _metadata;
  final PostDetails? _details;
  final DateTime? publishedAt;
  bool get isPublished => publishedAt != null;
  bool get isService =>
      metadata['postType'] == 'services' ||
      (metadata['postType'] == null &&
          (category == 'خدمات' || category == 'Services'));
  PostDetails get details => _details ?? PostDetails.fromJson(_metadata);

  /// Compatibility for existing JSON clients; UI code uses [details].
  Map<String, dynamic> get metadata => _details?.toJson() ?? _metadata;
  String get caption => details.caption;
  List<Map<String, dynamic>> get captionDelta => details.captionDelta;
  List<(String, String)> get features =>
      details.features.map((feature) => (feature.name, feature.value)).toList();

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageAsset': imageAsset,
    'title': title,
    'category': category,
    'profileCategoryId': profileCategoryId,
    'stockCount': stockCount,
    'price': price,
    'originalPrice': originalPrice,
    'media': media.map((entry) => entry.toJson()).toList(),
    'metadata': metadata,
    'publishedAt': publishedAt?.toUtc().toIso8601String(),
  };
  factory PostItem.fromJson(Map<String, dynamic> json) => PostItem(
    id: json['id'] as String,
    imageAsset: json['imageAsset'] as String? ?? '',
    title: json['title'] as String,
    category: json['category'] as String,
    profileCategoryId: json['profileCategoryId'] as String?,
    stockCount: json['stockCount'] as int,
    price: json['price'] as String,
    originalPrice: json['originalPrice'] as String,
    media: List.unmodifiable(
      (json['media'] as List? ?? []).map(
        (entry) => PostMedia.fromJson(Map<String, dynamic>.from(entry as Map)),
      ),
    ),
    details: PostDetails.fromJson(
      Map<String, dynamic>.from(json['metadata'] as Map? ?? {}),
    ),
    publishedAt: json['publishedAt'] == null
        ? null
        : DateTime.parse(json['publishedAt'] as String).toLocal(),
  );
}
