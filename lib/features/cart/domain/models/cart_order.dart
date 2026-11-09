// dart format width=100
import 'cart_item.dart';

import 'package:nini/features/order_cancellation/domain/order_cancellation.dart';

import 'cart_order_status.dart';
import '../../../payment/domain/models/payment_method.dart';
import '../../../payment/domain/models/order_customer_details.dart';
import '../../../payment/domain/models/order_dispute.dart';

import 'package:nini/shared/models/post/post_seller.dart';

/// Persistent local order/receipt. Demo payments are never bank confirmations.
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
    this.buyer,
    this.cancellation,
    this.providerReadAt,
    this.customerReadAt,
    this.address,
    this.phone,
    this.checkoutId,
    this.invoiceId,
    this.transactionId,
    this.paidAt,
    this.customer,
    this.dispute,
    this.isDemoPayment = false,
    Map<CartOrderStatus, DateTime> timeline = const {},
  }) : items = List.unmodifiable(items),
       timeline = Map.unmodifiable(timeline);

  final String id;
  final DateTime createdAt;
  final List<CartItem> items;
  final PaymentMethod method;
  final int charges;
  final CartOrderStatus? status;
  final PostSeller? seller, buyer;
  final OrderCancellation? cancellation;
  final DateTime? providerReadAt, customerReadAt;
  final String? customerId, address, phone, checkoutId, invoiceId, transactionId;
  final DateTime? paidAt;
  final OrderCustomerDetails? customer;
  final OrderDispute? dispute;
  final bool isDemoPayment;
  final Map<CartOrderStatus, DateTime> timeline;
  bool get isProductRequest => !isDemoPayment && seller != null && customerId != null;
  bool get isPaidReceipt => isDemoPayment && paidAt != null && invoiceId != null;
  int get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  int get discount => items.fold(0, (sum, item) => sum + item.discount);
  int get total => subtotal - discount + charges;

  /// Earlier receipts stored the provider only on their item snapshots.
  /// Recover it only when every item identifies the same provider.
  PostSeller? get provider {
    if (seller != null) return seller;
    if (items.isEmpty) return null;
    final first = items.first.seller;
    if (first == null || first.id.isEmpty) return null;
    return items.every((item) => item.seller?.id == first.id) ? first : null;
  }

  CartOrder withStatus(CartOrderStatus status) =>
      _copy(status: status, timeline: {...timeline, status: DateTime.now()});
  CartOrder withDispute(OrderDispute dispute) => _copy(
    status: CartOrderStatus.disputed,
    dispute: dispute,
    timeline: {...timeline, CartOrderStatus.disputed: dispute.createdAt},
  );
  CartOrder withCancellation(OrderCancellation value) => _copy(
    status: CartOrderStatus.canceled,
    cancellation: value,
    providerReadAt: value.createdAt,
    timeline: {...timeline, CartOrderStatus.canceled: value.createdAt},
  );
  CartOrder markRead({required bool asProvider}) => _copy(
    providerReadAt: asProvider ? DateTime.now() : providerReadAt,
    customerReadAt: asProvider ? customerReadAt : DateTime.now(),
  );
  CartOrder _copy({
    CartOrderStatus? status,
    OrderDispute? dispute,
    OrderCancellation? cancellation,
    DateTime? providerReadAt,
    DateTime? customerReadAt,
    Map<CartOrderStatus, DateTime>? timeline,
  }) => CartOrder(
    id: id,
    createdAt: createdAt,
    items: items,
    method: method,
    charges: charges,
    status: status ?? this.status,
    seller: seller,
    buyer: buyer,
    customerId: customerId,
    address: address,
    phone: phone,
    checkoutId: checkoutId,
    invoiceId: invoiceId,
    transactionId: transactionId,
    paidAt: paidAt,
    customer: customer,
    dispute: dispute ?? this.dispute,
    cancellation: cancellation ?? this.cancellation,
    providerReadAt: providerReadAt ?? this.providerReadAt,
    customerReadAt: customerReadAt ?? this.customerReadAt,
    isDemoPayment: isDemoPayment,
    timeline: timeline ?? this.timeline,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'items': items.map((item) => item.toJson()).toList(),
    'method': method.name,
    'charges': charges,
    'status': status?.name,
    if (seller != null) 'seller': seller!.toJson(),
    if (buyer != null) 'buyer': buyer!.toJson(),
    if (cancellation != null) 'cancellation': cancellation!.toJson(),
    if (providerReadAt != null) 'providerReadAt': providerReadAt!.toUtc().toIso8601String(),
    if (customerReadAt != null) 'customerReadAt': customerReadAt!.toUtc().toIso8601String(),
    if (customerId != null) 'customerId': customerId,
    if (address != null) 'address': address,
    if (phone != null) 'phone': phone,
    'timeline': {
      for (final event in timeline.entries) event.key.name: event.value.toUtc().toIso8601String(),
    },
    if (isDemoPayment) 'isDemoPayment': true,
    if (checkoutId != null) 'checkoutId': checkoutId,
    if (invoiceId != null) 'invoiceId': invoiceId,
    if (transactionId != null) 'transactionId': transactionId,
    if (paidAt != null) 'paidAt': paidAt!.toUtc().toIso8601String(),
    if (customer != null) 'customer': customer!.toJson(),
    if (dispute != null) 'dispute': dispute!.toJson(),
  };

  factory CartOrder.fromJson(Map<String, dynamic> json) => CartOrder(
    id: json['id'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
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
    buyer: json['buyer'] == null
        ? null
        : PostSeller.fromJson(Map<String, dynamic>.from(json['buyer'] as Map)),
    cancellation: json['cancellation'] == null
        ? null
        : OrderCancellation.fromJson(Map<String, dynamic>.from(json['cancellation'] as Map)),
    providerReadAt: json['providerReadAt'] == null
        ? null
        : DateTime.parse(json['providerReadAt'] as String).toLocal(),
    customerReadAt: json['customerReadAt'] == null
        ? null
        : DateTime.parse(json['customerReadAt'] as String).toLocal(),
    address: json['address'] as String?,
    phone: json['phone'] as String?,
    checkoutId: json['checkoutId'] as String?,
    invoiceId: json['invoiceId'] as String?,
    transactionId: json['transactionId'] as String?,
    paidAt: json['paidAt'] == null ? null : DateTime.parse(json['paidAt'] as String).toLocal(),
    customer: json['customer'] == null
        ? null
        : OrderCustomerDetails.fromJson(Map<String, dynamic>.from(json['customer'] as Map)),
    dispute: json['dispute'] == null
        ? null
        : OrderDispute.fromJson(Map<String, dynamic>.from(json['dispute'] as Map)),
    isDemoPayment: json['isDemoPayment'] as bool? ?? false,
    timeline: {
      for (final event in (json['timeline'] as Map? ?? {}).entries)
        ?CartOrderStatus.fromName(event.key as String): DateTime.parse(event.value as String)
            .toLocal(),
    },
  );
}
