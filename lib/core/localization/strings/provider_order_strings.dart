abstract final class ProviderOrderStrings {
  static const accept = 'Accept';
  static const accepted = 'Order accepted.';
  static const messageBuyer = 'Message buyer';
  static const messageProvider = 'Message provider';
  static const unavailable = 'This order is not available for your profile.';
  static const cancellation = 'Cancel order';
  static const cancellationHeading = 'Why are you canceling this order?';
  static const cancellationHint = 'Describe the reason for cancellation.';
  static const reasonRequired = 'Enter a cancellation reason.';
  static const cancelOrder = 'Submit cancellation';
  static const cancelled = 'Order canceled. The reason was saved locally.';
  static const cancellationReason = 'Provider cancellation';
  static const localNotice =
      'Saved on this device. No automatic refund or remote notification is sent.';
  static const startPreparing = 'Start preparing';
  static const markShipped = 'Mark shipped';
  static const schedule = 'Mark scheduled';
  static const startService = 'Start service';
  static const updated = 'Order status updated.';
  static const awaitingProvider =
      'Waiting for the provider to accept your order.';
  static const awaitingFulfillment =
      'Confirm completion becomes available after the provider ships the products or starts the service.';
  static const awaitingDelivery =
      'Confirm completion after receiving the products or service.';
  static const buyerDispute = 'The buyer reported a problem with this order.';
  static const acceptedNotice = 'Your order was accepted.';
  static const placedNotice = 'Your order was placed. Payment was successful.';
  static const completedNotice = 'Your order is completed.';
  static const buyerCompletedNotice = 'The buyer confirmed order completion.';
  static const manageSale = 'Manage sale';
  static const buyerInvoice = 'View buyer invoice';
  static const canceledNotice = 'The provider canceled your order.';
  static String statusNotice(String status) => 'Order status: $status';
}
