// dart format width=100
import 'cart_item.dart';
import 'cart_order.dart';

class CartSnapshot {
  CartSnapshot({required List<CartItem> items, List<CartOrder> orders = const []})
    : items = List.unmodifiable(items),
      orders = List.unmodifiable(orders);
  final List<CartItem> items;
  final List<CartOrder> orders;
  Map<String, dynamic> toJson() => {
    'version': 1,
    'items': items.map((item) => item.toJson()).toList(),
    'orders': orders.map((order) => order.toJson()).toList(),
  };
  factory CartSnapshot.fromJson(Map<String, dynamic> json) {
    if (json['version'] != 1) throw const FormatException('Unknown cart version');
    final items = (json['items'] as List)
        .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('Duplicate cart items');
    }
    return CartSnapshot(
      items: items,
      orders: (json['orders'] as List)
          .map((order) => CartOrder.fromJson(Map<String, dynamic>.from(order as Map)))
          .toList(),
    );
  }
}
