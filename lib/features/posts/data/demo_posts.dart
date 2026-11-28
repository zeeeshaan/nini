import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/shared/models/post/post_item.dart';

/// Exact historical shapes of unedited legacy seed posts.
///
/// Used only by [LocalPostsRepository] fingerprint matching so previously
/// persisted demo rows can be stripped. Not a production catalog — do not
/// surface these records in UI or seed new installs.
///
/// Matching compares complete `toJson()` fingerprints (not IDs alone) so
/// user-edited former samples are retained.
const demoPosts = <PostItem>[
  PostItem(
    id: 'post_1',
    imageAsset: 'assets/img1.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_2',
    imageAsset: 'assets/img2.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_3',
    imageAsset: 'assets/img3.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_4',
    imageAsset: 'assets/img2.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_5',
    imageAsset: 'assets/img3.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_6',
    imageAsset: 'assets/img1.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_7',
    imageAsset: 'assets/img1.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_8',
    imageAsset: 'assets/img2.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
  PostItem(
    id: 'post_9',
    imageAsset: 'assets/img3.png',
    title: AppStrings.headphoneTitle,
    category: AppStrings.mobile,
    stockCount: 2,
    price: '12,000',
    originalPrice: '13,000',
    details: PostDetails(unit: PostUnit.piece),
  ),
];
