// dart format width=100
import 'cart_item.dart';
import 'cart_order_status.dart';
import 'payment_method.dart';

/// A local preview receipt, never evidence of a real bank transaction.
class CartOrder {
  CartOrder({
    required this.id,
    required this.createdAt,
    required List<CartItem> items,
    required this.method,
    required this.charges,
    this.status = CartOrderStatus.completed,
  }) : items = List.unmodifiable(items);
  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final PaymentMethod method;
  final int charges;
  final CartOrderStatus? status;
  int get total => items.fold(charges, (sum, item) => sum + item.total);
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'method': method.name,
    'charges': charges,
    'status': status?.name,
  };
  factory CartOrder.fromJson(Map<String, dynamic> json) => CartOrder(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    items: (json['items'] as List)
        .map((item) => CartItem.fromJson(Map<String, dynamic>.from(item as Map)))
        .toList(),
    method: PaymentMethod.values.byName(json['method'] as String),
    charges: json['charges'] as int,
    status: json.containsKey('status')
        ? CartOrderStatus.fromName(json['status'] as String?)
        : CartOrderStatus.completed,
  );
}
