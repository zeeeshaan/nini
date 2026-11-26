import 'package:hywork/features/cart/domain/models/cart_item.dart';
import 'package:hywork/features/cart/presentation/helpers/cart_format.dart';
import 'package:hywork/shared/models/post/post_item.dart';
import 'package:hywork/shared/models/post/post_seller.dart';

/// Post prices are whole toman; cart quantities use hundredths of a unit.
CartItem? postCartItem(PostItem post, {PostSeller? seller}) {
  int? amount(String value) {
    final parsed = parseCartAmount(value.replaceAll(RegExp(r'[,٬\s]'), ''));
    return parsed != null && parsed % 100 == 0 ? parsed ~/ 100 : null;
  }

  final price = amount(post.price);
  final serviceWithoutInventory =
      post.isService && post.details.warehouseStock.trim().isEmpty;
  final stock = post.stockCount;
  // Null stock with confirmed availability means quantity is not tracked
  // (Create Post: stock null = not tracked), not a confirmed zero.
  final inventoryBlocked =
      !serviceWithoutInventory &&
      (post.isExplicitlyOutOfStock ||
          (stock == null && !post.isConfirmedAvailable));
  if (price == null || inventoryBlocked) {
    return null;
  }
  final original = amount(post.originalPrice);
  final basePrice = original != null && original > price ? original : price;
  return CartItem(
    id: post.id,
    title: post.title,
    category: post.category,
    unit:
        post.details.unit ??
        (post.isService ? PostUnit.session : PostUnit.piece),
    unitPrice: basePrice,
    discountPerUnit: basePrice - price,
    // Services / untracked stock use the Cart model's normal cap.
    maxQuantity: serviceWithoutInventory || stock == null
        ? 999900
        : stock * 100,
    imageUrl: post.media.isEmpty
        ? post.imageAsset
        : (post.media.first.type == PostMediaType.image
              ? post.media.first.path
              : post.media.first.thumbnailPath),
    seller: seller,
    isService: post.isService,
  );
}
