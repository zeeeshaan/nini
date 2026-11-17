// dart format width=100
import 'package:nini/core/localization/strings/cart_strings.dart';

/// Stable stored names; the menu filters these values without changing orders.
enum CartOrderStatus {
  paid(CartStrings.paid),
  pendingApproval(CartStrings.pendingApproval),
  canceled(CartStrings.canceled),
  unsuccessful(CartStrings.unsuccessful),
  pendingPay(CartStrings.pendingPay),
  failed(CartStrings.failed),
  refunded(CartStrings.refunded),
  accepted(CartStrings.accepted),
  scheduled(CartStrings.scheduled),
  returned(CartStrings.returned),
  disputed(CartStrings.disputed),
  completed(CartStrings.completed),
  preparing('Preparing order'),
  shipped('On the way'),
  inProgress('In progress');

  const CartOrderStatus(this.label);
  final String label;
  static CartOrderStatus? fromName(String? name) {
    for (final status in values) {
      if (status.name == name) return status;
    }
    return null;
  }
}
