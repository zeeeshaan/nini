import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/models/post/post_item.dart';

import 'demo_posts.dart';

/// Exact historical shapes of unedited legacy profile sample posts.
///
/// Used only by [LocalPostsRepository] fingerprint matching. These records are
/// not seeded on fresh installs and must not be shown as live profile data.
/// Complete JSON fingerprints preserve edited former samples.
List<PostItem> createProfileSamplePosts() => [
  for (final post in demoPosts) _editableSample(post),
];

PostItem _editableSample(PostItem post) {
  final price = double.parse(post.price.replaceAll(',', ''));
  final original = double.parse(
    (post.originalPrice.isEmpty ? post.price : post.originalPrice).replaceAll(
      ',',
      '',
    ),
  );
  final discount = original <= 0 ? 0.0 : (original - price) / original * 100;
  return PostItem(
    id: post.id,
    imageAsset: post.imageAsset,
    title: post.title,
    category: post.category,
    stockCount: post.stockCount,
    price: post.price,
    originalPrice: post.originalPrice,
    media: [
      PostMedia(
        path: post.imageAsset,
        name: post.title.replaceAll('\n', ' '),
        type: PostMediaType.image,
        source: PostMediaSource.asset,
      ),
    ],
    details: PostDetails.fromJson({
      ...post.metadata,
      'postType': 'product',
      'caption': AppStrings.caption,
      'price': original.toString(),
      'discount': discount == 0 ? '' : discount.toString(),
      'warehouseStock': post.stockCount?.toString() ?? '',
      'features': [
        for (final feature in AppStrings.features)
          {'name': feature.$1, 'value': feature.$2},
      ],
    }),
  );
}
