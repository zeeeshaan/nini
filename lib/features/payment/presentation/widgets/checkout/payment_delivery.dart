import 'package:flutter/material.dart';
import 'package:nini/core/localization/strings/order_information_strings.dart';
import 'package:nini/core/localization/strings/payment_strings.dart';
import 'package:nini/core/theme/app_text_styles.dart';
import 'package:nini/features/payment/domain/models/payment_details.dart';

/// Read-only buyer table populated from the preceding information form.
class PaymentDelivery extends StatelessWidget {
  const PaymentDelivery({super.key, required this.details});
  final PaymentDetails details;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final customer = details.customer;
    final rows = [
      (OrderInformationStrings.name, customer?.name ?? ''),
      (OrderInformationStrings.surname, customer?.surname ?? ''),
      (OrderInformationStrings.mobile, customer?.mobile ?? details.phone ?? ''),
      (OrderInformationStrings.city, customer?.city ?? ''),
      (OrderInformationStrings.province, customer?.province ?? ''),
      (
        OrderInformationStrings.address,
        customer?.address ?? details.address ?? '',
      ),
      (OrderInformationStrings.postalCode, customer?.postalCode ?? ''),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          PaymentStrings.buyerInformation,
          textAlign: TextAlign.right,
          style: AppTextStyles.sectionTitle,
          textDirection: TextDirection.ltr,
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var index = 0; index < rows.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 5,
                        child: Text(
                          rows[index].$2,
                          textDirection: index == 2 || index == 6
                              ? TextDirection.ltr
                              : TextDirection.ltr,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: AppTextStyles.medium,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 3,
                        child: Text(
                          rows[index].$1,
                          textAlign: TextAlign.right,
                          style: AppTextStyles.label.copyWith(
                            color: colors.onSurface.withValues(alpha: .7),
                          ),
                          textDirection: TextDirection.ltr,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
