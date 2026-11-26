import 'package:hywork/core/localization/app_string/app_string.dart';
import 'package:hywork/core/localization/strings/home_strings.dart';
import 'package:hywork/shared/models/local_identity.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

// The existing Home preview stays separate from the user's saved Posts.
const homeSeller = PostSeller(
  id: 'home-seller',
  name: AppStrings.sellerName,
  avatarAsset: '',
  location: AppStrings.authorLocation,
  bio: AppStrings.sellerBio,
);

const localPostSeller = PostSeller(
  id: localProfileId,
  name: '',
  avatarAsset: '',
  bio: '',
);

PostItem homeProductPost({required String title, required String imageUrl}) =>
    PostItem(
      id: 'home-pixel9',
      title: title,
      imageAsset: imageUrl,
      category: HomeStrings.mobile,
      stockCount: 2,
      price: '12,000',
      originalPrice: '13,000',
      details: PostDetails(unit: PostUnit.piece, warehouseStock: '2'),
    );
