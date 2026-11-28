import 'package:hywork/shared/models/post/post_seller.dart';
import 'package:hywork/features/payment/domain/models/payment_details.dart';
import 'package:hywork/features/payment/domain/models/payment_method.dart';

import '../models/cart_item.dart';
import '../models/cart_order.dart';

/// Each provider receives only their own items and share of checkout charges.
List<CartOrder> buildDemoCheckoutOrders({
  required PaymentDetails details,
  required PaymentMethod method,
  required PostSeller buyer,
  required int charges,
  required DateTime now,
}) {
  if (details.customer == null || details.checkoutId == null) return const [];
  final groups = <(String, bool), List<CartItem>>{};
  for (final item in details.items) {
    final seller = item.seller;
    if (seller == null || seller.id.isEmpty) return const [];
    groups.putIfAbsent((seller.id, item.isService), () => []).add(item);
  }
  final total = details.items.fold(0, (sum, item) => sum + item.total);
  var remainingCharges = charges;
  final orders = <CartOrder>[];
  for (final items in groups.values) {
    final index = orders.length + 1;
    final groupTotal = items.fold(0, (sum, item) => sum + item.total);
    final share = index == groups.length
        ? remainingCharges
        : (total == 0 ? 0 : charges * groupTotal ~/ total);
    remainingCharges -= share;
    final stamp = '${now.microsecondsSinceEpoch}-$index';
    orders.add(
      CartOrder(
        id: 'HW-$stamp',
        checkoutId: details.checkoutId,
        invoiceId: 'INV-${now.year}-$stamp',
        transactionId: 'DEMO-TX-${now.microsecondsSinceEpoch}',
        createdAt: now,
        paidAt: now,
        items: items,
        seller: items.first.seller,
        buyer: buyer,
        customerId: buyer.id,
        method: method,
        charges: share,
        customer: details.customer,
        address: details.customer!.address,
        phone: details.customer!.mobile,
        isDemoPayment: true,
        status: CartOrderStatus.paid,
        timeline: {CartOrderStatus.paid: now},
      ),
    );
  }
  return orders;
}
