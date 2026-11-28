import 'package:hywork/shared/models/local_identity.dart';

import '../models/cart_order.dart';

/// One profile can be the buyer on one order and provider on another.
abstract final class OrderAccess {
  static const _activePurchaseStatuses = {
    CartOrderStatus.paid,
    CartOrderStatus.accepted,
    CartOrderStatus.preparing,
    CartOrderStatus.shipped,
    CartOrderStatus.scheduled,
    CartOrderStatus.inProgress,
  };
  static bool isBuyer(CartOrder order, String userId) =>
      order.customerId == userId ||
      (userId == localProfileId &&
          (order.customerId == 'local-customer' ||
              (order.customerId == null &&
                  (order.isDemoPayment || order.seller == null))));

  static bool isProvider(CartOrder order, String userId) =>
      order.provider?.id == userId &&
      order.items.isNotEmpty &&
      order.items.every(
        (item) => item.seller == null || item.seller!.id == userId,
      );

  static bool canAccept(CartOrder order, String userId) =>
      isProvider(order, userId) &&
      ((order.isPaidReceipt && order.status == CartOrderStatus.paid) ||
          (order.isProductRequest &&
              order.status == CartOrderStatus.pendingApproval));

  static bool canCancel(CartOrder order, String userId) =>
      isProvider(order, userId) &&
      const {
        CartOrderStatus.paid,
        CartOrderStatus.pendingApproval,
        CartOrderStatus.pendingPay,
        CartOrderStatus.accepted,
        CartOrderStatus.preparing,
        CartOrderStatus.scheduled,
      }.contains(order.status);

  static bool canDispute(CartOrder order, String userId) =>
      isBuyer(order, userId) &&
      order.isPaidReceipt &&
      _activePurchaseStatuses.contains(order.status);

  static bool canComplete(CartOrder order, String userId) =>
      isBuyer(order, userId) &&
      order.isPaidReceipt &&
      (order.status == CartOrderStatus.shipped ||
          order.status == CartOrderStatus.inProgress ||
          (order.provider == null && order.status == CartOrderStatus.paid));

  static CartOrderStatus? nextProviderStatus(CartOrder order, String userId) {
    if (!isProvider(order, userId) || !order.isPaidReceipt) return null;
    return switch (order.status) {
      CartOrderStatus.accepted =>
        order.items.every((item) => item.isService)
            ? CartOrderStatus.scheduled
            : CartOrderStatus.preparing,
      CartOrderStatus.preparing => CartOrderStatus.shipped,
      CartOrderStatus.scheduled => CartOrderStatus.inProgress,
      _ => null,
    };
  }
}
