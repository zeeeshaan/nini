import 'order_customer_details.dart';

import 'package:hywork/features/cart/models/cart_item.dart';

/// Display data supplied by a checkout. Monetary values use hundredths of toman.
class PaymentDetails {
  const PaymentDetails({
    required this.total,
    required this.summary,
    this.scheduledAt,
    this.address,
    this.phone,
    this.customer,
    this.items = const [],
    this.checkoutId,
  });
  final int total;
  final List<(String, String)> summary;
  final DateTime? scheduledAt;
  final String? address, phone;
  final OrderCustomerDetails? customer;
  final List<CartItem> items;
  final String? checkoutId;
}
