import 'package:nini/features/create_post/domain/models/post_draft.dart';
import 'package:nini/shared/models/post/post_item.dart';

/// Rehydrates every stored editor field. In particular, use the base price,
/// not the discounted display price, so editing never applies a discount twice.
PostDraft postDraftFromPost(PostItem post) {
  final data = post.metadata;
  final details = post.details;
  return PostDraft(
    postType: post.isService ? CreatePostType.services : CreatePostType.product,
    profileCategoryId: post.profileCategoryId,
    title: post.title,
    caption: post.caption,
    captionDelta: post.captionDelta,
    price:
        data['price']?.toString() ??
        (post.originalPrice.isEmpty ? post.price : post.originalPrice),
    discount: details.discount,
    warehouseStock: details.warehouseStock.isEmpty
        ? '${post.stockCount}'
        : details.warehouseStock,
    unit: details.unit ?? PostUnit.piece,
    preparationTime: PreparationTime.values.firstWhere(
      (value) => value.days == data['preparationDays'],
      orElse: () => PreparationTime.none,
    ),
    inventoryStatus: InventoryStatus.values.firstWhere(
      (value) => value.name == data['inventoryStatus'],
      orElse: () => InventoryStatus.inStock,
    ),
    schedule: details.schedule,
    address: details.address,
    savedAddresses: details.address == null ? const [] : [details.address!],
    features: details.features,
    tags: details.tags,
    altTexts: details.altTexts,
  );
}
