import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nini/core/icons/app_icons.dart';
import 'package:nini/core/localization/app_string/app_string.dart';
import 'package:nini/core/localization/strings/receipt_strings.dart';
import 'package:nini/core/theme/app_colors.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/cart/domain/models/cart_order.dart';
import 'package:nini/shared/widgets/app_icons/app_icon.dart';
import 'package:nini/shared/widgets/app_toast/app_toast.dart';

class InvoiceMetadata extends StatelessWidget {
  const InvoiceMetadata({super.key, required this.order, this.payment = false});
  final CartOrder order;
  final bool payment;

  @override
  Widget build(BuildContext context) {
    final paidAt = order.paidAt ?? order.createdAt;
    final date = MaterialLocalizations.of(context).formatMediumDate(paidAt);
    final rows = payment
        ? [
            (ReceiptStrings.paymentMethod, order.method.label),
            (ReceiptStrings.paymentDate, date),
            (
              ReceiptStrings.paymentTime,
              MaterialLocalizations.of(context)
                  .formatTimeOfDay(TimeOfDay.fromDateTime(paidAt)),
            ),
            (ReceiptStrings.currency, AppStrings.toman),
          ]
        : [
            (ReceiptStrings.invoiceDate, date),
            (ReceiptStrings.orderId, order.id),
            (ReceiptStrings.transactionId, order.transactionId ?? ''),
          ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (payment)
            const Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    ReceiptStrings.paymentSuccessful,
                    style: AppTextStyles.sectionTitle,
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                SizedBox(width: 6),
                Icon(
                  Icons.check_circle_outline,
                  size: 18,
                  color: AppColors.walletCredit,
                ),
              ],
            )
          else
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: order.invoiceId ?? order.id),
                  );
                  if (context.mounted) {
                    AppToast.success(context, ReceiptStrings.copied);
                  }
                },
                icon: const AppIcon(AppIcons.copy, size: 16),
                label: Text(
                  order.invoiceId ?? order.id,
                  style: AppTextStyles.bodyEmphasis,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
              ),
            ),
          const SizedBox(height: 8),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      row.$2,
                      style: AppTextStyles.body.copyWith(
                        fontWeight: AppTextStyles.medium,
                      ),
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      row.$1,
                      textAlign: TextAlign.right,
                      style: AppTextStyles.label,
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          if (order.isDemoPayment) ...[
            const SizedBox(height: 10),
            const Text(
              ReceiptStrings.demoNotice,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallPrint,
              textDirection: TextDirection.rtl,
            ),
          ],
        ],
      ),
    );
  }
}
