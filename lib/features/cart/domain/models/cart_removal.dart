import 'cart_item.dart';

/// A short-lived undo snapshot; it is never written to cart storage.
class CartRemoval {
  CartRemoval({
    required this.item,
    required this.expiresAt,
    required List<String> itemOrder,
  }) : itemOrder = List.unmodifiable(itemOrder);

  final CartItem item;
  final DateTime expiresAt;
  final List<String> itemOrder;
}
