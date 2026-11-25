import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/provider_order_strings.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_text_styles/app_text_styles.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/features/payment/presentation/helpers/receipt_details.dart';
import 'package:nini/features/payment/presentation/widgets/dispute/dispute_attachment_tile.dart';
import 'package:nini/features/payment/presentation/widgets/checkout/payment_delivery.dart';
import 'package:nini/features/payment/presentation/widgets/checkout/payment_escrow.dart';
import 'package:nini/features/payment/presentation/widgets/checkout/payment_order_details.dart';
import 'package:nini/features/payment/presentation/widgets/checkout/payment_summary.dart';

import 'invoice_metadata.dart';

/// Both invoice views display the same immutable order snapshot.
class OrderInvoiceContent extends StatelessWidget {
  const OrderInvoiceContent({super.key, required this.order, this.statusHint});
  final CartOrder order;
  final String? statusHint;
  @override
  Widget build(BuildContext context) {
    final details = receiptDetails(order);
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InvoiceMetadata(order: order),
              const SizedBox(height: 20),
              PaymentOrderDetails(details: details),
              const SizedBox(height: 16),
              PaymentDelivery(details: details),
              const SizedBox(height: 20),
              PaymentSummary(details: details),
              const SizedBox(height: 20),
              if (order.paidAt != null) ...[
                InvoiceMetadata(order: order, payment: true),
                const SizedBox(height: 20),
              ],
              if (order.status != null) ...[
                Text(
                  order.status!.label,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyBold,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 12),
              ],
              if (statusHint != null) ...[
                Text(
                  statusHint!,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyText,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 12),
              ],
              if (order.cancellation != null) ...[
                const Text(
                  ProviderOrderStrings.cancellationReason,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.sectionTitle,
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  order.cancellation!.reason,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                for (final attachment in order.cancellation!.attachments)
                  DisputeAttachmentTile(attachment: attachment),
                const Text(
                  ProviderOrderStrings.localNotice,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.bodyText,
                  textDirection: TextDirection.ltr,
                ),
                const SizedBox(height: 16),
              ],
              if (order.dispute != null) ...[
                const Text(
                  ReceiptStrings.dispute,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.sectionTitle,
                  textDirection: TextDirection.ltr,
                ),
                Text(
                  order.dispute!.description,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.ltr,
                ),
                for (final attachment in order.dispute!.attachments)
                  DisputeAttachmentTile(attachment: attachment),
                const SizedBox(height: 16),
              ],
              const PaymentEscrow(),
            ],
          ),
        ),
      ),
    );
  }
}
