import 'package:hywork/core/localization/strings/cart_strings.dart';
import 'package:hywork/features/cart/models/cart_order.dart';
import 'package:hywork/features/cart/utils/cart_helpers.dart';
import 'package:hywork/features/payment/domain/models/payment_details.dart';

PaymentDetails receiptDetails(CartOrder order) => PaymentDetails(
  total: order.total,
  summary: [
    (CartStrings.subtotal, cartMoney(order.subtotal)),
    (CartStrings.discount, cartMoney(order.discount)),
    (CartStrings.charges, cartMoney(order.charges)),
  ],
  customer: order.customer,
  address: order.address,
  phone: order.phone,
  items: order.items,
  checkoutId: order.checkoutId,
);
