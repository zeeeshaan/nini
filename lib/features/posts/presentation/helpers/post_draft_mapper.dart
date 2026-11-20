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
    categoryKey: data['category'] as String?,
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

/// Rehydrates values that are representable by the existing editor; the raw
/// owner response remains authoritative for all comparisons and nulls.
PostDraft postDraftFromBackend(PostItem post, Map<String, dynamic> data) {
  final base = postDraftFromPost(post);
  final price = data['price'];
  final discount = data['discountPrice'];
  var percent = '';
  if (price is int &&
      price > 0 &&
      discount is int &&
      discount >= 0 &&
      discount < price) {
    final scaled = BigInt.from(price - discount) * BigInt.from(10000);
    if (scaled % BigInt.from(price) == BigInt.zero) {
      final points = (scaled ~/ BigInt.from(price)).toInt();
      percent = points % 100 == 0
          ? '${points ~/ 100}'
          : '${points ~/ 100}.${(points % 100).toString().padLeft(2, '0')}';
    }
  }
  final start = data['scheduleStart'] is String
      ? DateTime.tryParse(data['scheduleStart'] as String)
      : null;
  final end = data['scheduleEnd'] is String
      ? DateTime.tryParse(data['scheduleEnd'] as String)
      : null;
  final stock = data['stock'];
  final inventory = data['inventoryStatus'];
  final preparation = data['preparationTime'];
  return base.copyWith(
    discount: percent,
    warehouseStock: stock is int ? '$stock' : '',
    inventoryStatus: inventory == 'out_of_stock'
        ? InventoryStatus.outOfStock
        : InventoryStatus.inStock,
    preparationTime: PreparationTime.values.firstWhere(
      (v) => v.label == preparation,
      orElse: () => PreparationTime.none,
    ),
    schedule: start != null && end != null
        ? PostSchedule(startsAt: start.toLocal(), endsAt: end.toLocal())
        : null,
    clearSchedule: start == null || end == null,
  );
}
