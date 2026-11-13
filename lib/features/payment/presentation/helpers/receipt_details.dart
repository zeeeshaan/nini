import 'package:nini/core/localization/strings/cart_strings.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/cart/presentation/helpers/cart_format.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';

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
