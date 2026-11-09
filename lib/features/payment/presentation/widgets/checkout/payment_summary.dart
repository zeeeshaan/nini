import 'package:flutter/material.dart';
import 'package:nini/core/localization/app_strings.dart';
import 'package:nini/core/localization/cart_strings.dart';
import 'package:nini/core/localization/payment_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';
import 'package:nini/features/payment/presentation/helpers/payment_money.dart';

class PaymentSummary extends StatelessWidget {
  const PaymentSummary({super.key, required this.details});
  final PaymentDetails details;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        PaymentStrings.paymentDetails,
        textAlign: TextAlign.right,
        style: AppTextStyles.labelBold,
      ),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 6),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            for (final row in details.summary)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Text(
                        row.$2,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.labelBold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: Text(
                        row.$1 == CartStrings.charges
                            ? PaymentStrings.additionalCharges
                            : row.$1,
                        textAlign: TextAlign.right,
                        style: AppTextStyles.label,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      paymentMoney(details.total),
                      style: AppTextStyles.pageTitleBold,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      '${PaymentStrings.totalAmountDue} (${AppStrings.toman})',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelBold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
