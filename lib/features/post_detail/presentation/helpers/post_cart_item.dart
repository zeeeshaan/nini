import 'package:nini/features/cart/domain/models/cart_item.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/shared/models/post/post_item.dart';
import 'package:nini/shared/models/post/post_seller.dart';

/// Post prices are whole toman; cart quantities use hundredths of a unit.
CartItem? postCartItem(PostItem post, {PostSeller? seller}) {
  int? amount(String value) {
    final parsed = parseCartAmount(value.replaceAll(RegExp(r'[,٬\s]'), ''));
    return parsed != null && parsed % 100 == 0 ? parsed ~/ 100 : null;
  }

  final price = amount(post.price);
  if (price == null || post.stockCount <= 0) return null;
  final original = amount(post.originalPrice);
  final basePrice = original != null && original > price ? original : price;
  return CartItem(
    id: post.id,
    title: post.title,
    category: post.category,
    unit: post.details.unit ?? PostUnit.piece,
    unitPrice: basePrice,
    discountPerUnit: basePrice - price,
    maxQuantity: post.stockCount * 100,
    imageUrl: post.media.isEmpty
        ? post.imageAsset
        : (post.media.first.type == PostMediaType.image
              ? post.media.first.path
              : post.media.first.thumbnailPath),
    seller: seller,
  );
}
