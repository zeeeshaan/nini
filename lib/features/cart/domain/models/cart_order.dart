// dart format width=100
import 'cart_item.dart';
import 'cart_order_status.dart';
import '../../../payment/domain/models/payment_method.dart';

import 'package:nini/shared/models/post/post_seller.dart';

/// A local preview receipt, never evidence of a real bank transaction.
class CartOrder {
  CartOrder({
    required this.id,
    required this.createdAt,
    required List<CartItem> items,
    required this.method,
    required this.charges,
    this.status = CartOrderStatus.completed,
    this.seller,
    this.customerId,
    this.address,
    this.phone,
    Map<CartOrderStatus, DateTime> timeline = const {},
  }) : items = List.unmodifiable(items),
       timeline = Map.unmodifiable(timeline);
  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final PaymentMethod method;
  final int charges;
  final CartOrderStatus? status;
  final PostSeller? seller;
  final String? customerId, address, phone;
  final Map<CartOrderStatus, DateTime> timeline;
  bool get isProductRequest => seller != null && customerId != null;
  int get total => items.fold(charges, (sum, item) => sum + item.total);

  CartOrder withStatus(CartOrderStatus status) => CartOrder(
    id: id,
    createdAt: createdAt,
    items: items,
    method: method,
    charges: charges,
    status: status,
    seller: seller,
    customerId: customerId,
    address: address,
    phone: phone,
    timeline: {...timeline, status: DateTime.now()},
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'method': method.name,
    'charges': charges,
    'status': status?.name,
    if (isProductRequest) ...{
      'seller': seller!.toJson(),
      'customerId': customerId,
      'address': address,
      'phone': phone,
      'timeline': {
        for (final event in timeline.entries) event.key.name: event.value.toIso8601String(),
      },
    },
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
    seller: json['seller'] == null
        ? null
        : PostSeller.fromJson(Map<String, dynamic>.from(json['seller'] as Map)),
    customerId: json['customerId'] as String?,
    address: json['address'] as String?,
    phone: json['phone'] as String?,
    timeline: {
      for (final event in (json['timeline'] as Map? ?? {}).entries)
        ?CartOrderStatus.fromName(event.key as String): DateTime.parse(event.value as String),
    },
  );
}
